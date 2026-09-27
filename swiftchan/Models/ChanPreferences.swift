import SwiftUI
import FourChan
import Observation

enum ChanTheme: String, CaseIterable, Identifiable {
    case system = "System", yotsuba = "Yotsuba", yotsubaB = "Yotsuba B"
    var id: String { rawValue }
    var postBackground: Color {
        switch self {
        case .system: return Color(UIColor.systemBackground)
        case .yotsuba: return Color(red: 0.94, green: 0.88, blue: 0.84)
        case .yotsubaB: return Color(red: 0.84, green: 0.85, blue: 0.94)
        }
    }
    var pageBackground: Color {
        switch self {
        case .system: return Color(UIColor.systemBackground)
        case .yotsuba: return Color(red: 1, green: 1, blue: 0.93)
        case .yotsubaB: return Color(red: 0.93, green: 0.95, blue: 1)
        }
    }
}

struct PostFilterRule: Codable, Identifiable, Equatable {
    enum Field: String, Codable, CaseIterable { case keyword = "Keyword", posterID = "Poster ID", name = "Name", tripcode = "Tripcode" }
    enum Action: String, Codable, CaseIterable { case hide = "Hide", highlight = "Highlight" }
    var id = UUID()
    var board: String?
    var field: Field
    var pattern: String
    var action: Action

    func matches(board: String, text: String, posterID: String?, name: String?, tripcode: String?) -> Bool {
        guard self.board == nil || self.board == board.lowercased(), !pattern.isEmpty else { return false }
        let value: String
        switch field {
        case .keyword: value = text
        case .posterID: return posterID?.caseInsensitiveCompare(pattern) == .orderedSame
        case .name: value = name ?? ""
        case .tripcode: value = tripcode ?? ""
        }
        return value.localizedStandardContains(pattern)
    }
}

@Observable @MainActor
final class PostFilterStore {
    static let shared = PostFilterStore(defaults: ProcessInfo.processInfo.arguments.contains("--ui-testing") ? nil : .standard)
    private(set) var rules: [PostFilterRule]
    @ObservationIgnored private let defaults: UserDefaults?
    private let key = "postFilters.v1"

    init(defaults: UserDefaults? = .standard) {
        self.defaults = defaults
        rules = defaults?.data(forKey: key).flatMap { try? JSONDecoder().decode([PostFilterRule].self, from: $0) } ?? []
    }

    func add(_ rule: PostFilterRule) {
        var rule = rule
        rule.pattern = rule.pattern.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rule.pattern.isEmpty else { return }
        if let board = rule.board {
            guard let normalized = Deeplinker.normalizedBoard(board) else { return }
            rule.board = normalized
        }
        rules.append(rule)
        persist()
    }

    func remove(_ rule: PostFilterRule) {
        rules.removeAll { $0.id == rule.id }
        persist()
    }

    func effect(board: String, post: Post, text: String) -> PostFilterRule.Action? {
        let matches = rules.filter { $0.matches(board: board, text: "\(post.sub?.clean ?? "") \(text)",
                                                posterID: post.pid, name: post.name, tripcode: post.trip) }
        if matches.contains(where: { $0.action == .hide }) { return .hide }
        return matches.isEmpty ? nil : .highlight
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(rules) { defaults?.set(data, forKey: key) }
    }
}
