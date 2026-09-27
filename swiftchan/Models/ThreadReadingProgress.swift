import Foundation
import Observation

struct ThreadReadingProgress: Codable, Equatable {
    var postID: Int
    var highestReadID: Int
    var updatedAt: Date
    var title: String?
}

struct RecentThread: Identifiable {
    let board: String
    let threadID: Int
    let progress: ThreadReadingProgress
    var id: String { "\(board)/\(threadID)" }
    var title: String { progress.title ?? "Thread #\(threadID)" }
}

/// Small, bounded local reading metadata, independent of saved favorites and their schema.
@Observable @MainActor
final class ThreadReadingStore {
    static let shared: ThreadReadingStore = {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
            let store = ThreadReadingStore(defaults: nil)
            if ProcessInfo.processInfo.arguments.contains("--ui-reading-seed") {
                store.record(board: "biz", threadID: 100, postID: 105, highestReadID: 105)
            }
            return store
        }
        #endif
        return ThreadReadingStore()
    }()

    private(set) var resetID = UUID()
    private var revision = 0
    @ObservationIgnored private let defaults: UserDefaults?
    private let key = "threadReadingProgress.v1"
    private let limit: Int
    @ObservationIgnored private var entries: [String: ThreadReadingProgress]
    @ObservationIgnored private var dirty = false

    init(defaults: UserDefaults? = .standard, limit: Int = 300) {
        self.defaults = defaults
        self.limit = max(1, limit)
        entries = defaults?.data(forKey: key).flatMap { try? JSONDecoder().decode([String: ThreadReadingProgress].self, from: $0) } ?? [:]
    }

    func progress(board: String, threadID: Int) -> ThreadReadingProgress? {
        entries["\(board.lowercased())/\(threadID)"]
    }

    var recentThreads: [RecentThread] {
        _ = revision
        return entries.compactMap { key, progress -> RecentThread? in
            let parts = key.split(separator: "/")
            guard parts.count == 2, let board = Deeplinker.normalizedBoard(String(parts[0])),
                  let threadID = Int(parts[1]), threadID > 0 else { return nil }
            return RecentThread(board: board, threadID: threadID, progress: progress)
        }.sorted {
            $0.progress.updatedAt == $1.progress.updatedAt ? $0.id < $1.id : $0.progress.updatedAt > $1.progress.updatedAt
        }
    }

    func record(board: String, threadID: Int, postID: Int, highestReadID: Int, now: Date = Date(), title: String? = nil) {
        guard threadID > 0, postID > 0, let board = Deeplinker.normalizedBoard(board) else { return }
        let identity = "\(board)/\(threadID)"
        let title = title.map { String($0.trimmingCharacters(in: .whitespacesAndNewlines).prefix(512)) }
            .flatMap { $0.isEmpty ? nil : $0 }
        entries[identity] = ThreadReadingProgress(postID: postID,
            highestReadID: max(postID, highestReadID, entries[identity]?.highestReadID ?? 0), updatedAt: now,
            title: title ?? entries[identity]?.title)
        if entries.count > limit {
            let retained = entries.sorted { $0.value.updatedAt > $1.value.updatedAt }.prefix(limit)
            entries = Dictionary(uniqueKeysWithValues: retained.map { ($0.key, $0.value) })
        }
        dirty = true
    }

    func flush() {
        guard dirty, let data = try? JSONEncoder().encode(entries) else { return }
        defaults?.set(data, forKey: key)
        dirty = false
        revision += 1
    }

    func remove(_ thread: RecentThread) {
        entries.removeValue(forKey: thread.id)
        dirty = true
        flush()
    }

    func clear() {
        entries.removeAll()
        resetID = UUID()
        defaults?.removeObject(forKey: key)
        dirty = false
        revision += 1
    }
}

/// Per-visit state keeps restoration and unread accounting out of scroll callbacks.
struct ThreadReadingSession {
    private(set) var started = false
    private(set) var postID: Int?
    private(set) var highestReadID = 0
    private(set) var unreadBoundary: Int?
    private(set) var pendingRestore: Int?

    mutating func start(postIDs: [Int], saved: ThreadReadingProgress?, linkedPostID: Int?) -> Int? {
        guard !started, !postIDs.isEmpty else { return nil }
        started = true
        highestReadID = saved?.highestReadID ?? 0
        // Existing posts aren't labelled new on a first visit; later refreshes can add new replies.
        unreadBoundary = saved?.highestReadID ?? postIDs.max()
        let requested = linkedPostID ?? saved?.postID
        if let requested {
            pendingRestore = postIDs.first(where: { $0 >= requested }) ?? postIDs.last
        }
        return pendingRestore
    }

    mutating func observe(visiblePostIDs: [Int]) {
        guard started, let first = visiblePostIDs.min(), let last = visiblePostIDs.max() else { return }
        if let pendingRestore {
            guard visiblePostIDs.contains(pendingRestore) else { return }
            self.pendingRestore = nil
        }
        postID = first
        highestReadID = max(highestReadID, last)
    }

    func unreadPostIDs(in postIDs: [Int]) -> [Int] {
        guard let unreadBoundary else { return [] }
        let readThrough = max(unreadBoundary, highestReadID)
        return postIDs.filter { $0 > readThrough }
    }

    func firstNewPostID(in postIDs: [Int]) -> Int? {
        guard let unreadBoundary else { return nil }
        return postIDs.first { $0 > unreadBoundary }
    }
}
