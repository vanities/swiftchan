import Foundation
import Observation

struct ThreadReadingProgress: Codable, Equatable {
    var postID: Int
    var highestReadID: Int
    var updatedAt: Date
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

    func record(board: String, threadID: Int, postID: Int, highestReadID: Int, now: Date = Date()) {
        guard threadID > 0, postID > 0 else { return }
        let identity = "\(board.lowercased())/\(threadID)"
        entries[identity] = ThreadReadingProgress(postID: postID,
            highestReadID: max(postID, highestReadID, entries[identity]?.highestReadID ?? 0), updatedAt: now)
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
    }

    func clear() {
        entries.removeAll()
        resetID = UUID()
        defaults?.removeObject(forKey: key)
        dirty = false
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
