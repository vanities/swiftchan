import Foundation
import Observation

struct HiddenPost: Codable, Identifiable, Equatable {
    let boardName: String
    let postID: Int
    let threadID: Int?
    let title: String?
    let hiddenAt: Date

    var id: String { "\(boardName)/\(postID)" }
    var isThread: Bool { threadID == postID }
    var label: String { title ?? "\(isThread ? "Thread" : "Post") #\(postID)" }
}

/// Observable visibility state, including the individual flags written by older app versions.
@Observable @MainActor
final class HiddenPostStore {
    static let shared: HiddenPostStore = {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") { return HiddenPostStore(defaults: nil) }
        #endif
        return HiddenPostStore()
    }()

    @ObservationIgnored private let defaults: UserDefaults?
    private let storageKey = "hiddenPosts.v1"
    private var entries: [String: HiddenPost]

    var items: [HiddenPost] {
        entries.values.sorted {
            $0.hiddenAt == $1.hiddenAt ? $0.id < $1.id : $0.hiddenAt > $1.hiddenAt
        }
    }

    init(defaults: UserDefaults? = .standard) {
        self.defaults = defaults
        entries = defaults?.data(forKey: storageKey).flatMap { try? JSONDecoder().decode([String: HiddenPost].self, from: $0) } ?? [:]
        // Keep legacy keys until the user restores those entries, avoiding destructive migration.
        for (key, _) in defaults?.dictionaryRepresentation() ?? [:] {
            guard defaults?.bool(forKey: key) == true,
                  let identity = Self.legacyIdentity(key), entries[identity.id] == nil else { continue }
            entries[identity.id] = identity
        }
    }

    func isHidden(board: String, postID: Int) -> Bool {
        entries["\(board.lowercased())/\(postID)"] != nil
    }

    @discardableResult
    func hide(board: String, postID: Int, threadID: Int? = nil, title: String? = nil, now: Date = Date()) -> HiddenPost? {
        guard let board = Deeplinker.normalizedBoard(board), postID > 0 else { return nil }
        let identity = "\(board)/\(postID)"
        if let existing = entries[identity] { return existing }
        let trimmedTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines)
        let item = HiddenPost(boardName: board, postID: postID, threadID: threadID,
                              title: trimmedTitle?.isEmpty == false ? trimmedTitle : nil, hiddenAt: now)
        entries[identity] = item
        persist()
        return item
    }

    func restore(_ item: HiddenPost) {
        entries.removeValue(forKey: item.id)
        removeLegacyFlags(for: Set([item.id]))
        persist()
    }

    func restoreAll() {
        let identities = Set(entries.keys)
        entries.removeAll()
        removeLegacyFlags(for: identities)
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults?.set(data, forKey: storageKey)
    }

    private func removeLegacyFlags(for identities: Set<String>) {
        for key in defaults?.dictionaryRepresentation().keys ?? [String: Any]().keys {
            if let item = Self.legacyIdentity(key), identities.contains(item.id) { defaults?.removeObject(forKey: key) }
        }
    }

    private static func legacyIdentity(_ key: String) -> HiddenPost? {
        let prefix = "hiddenPosts board="
        guard key.hasPrefix(prefix) else { return nil }
        let pieces = key.dropFirst(prefix.count).components(separatedBy: " postId=")
        guard pieces.count == 2, let board = Deeplinker.normalizedBoard(pieces[0]),
              !pieces[1].isEmpty, pieces[1].utf8.allSatisfy({ (48...57).contains($0) }),
              let id = Int(pieces[1]), id > 0 else { return nil }
        return HiddenPost(boardName: board, postID: id, threadID: nil, title: nil, hiddenAt: .distantPast)
    }
}
