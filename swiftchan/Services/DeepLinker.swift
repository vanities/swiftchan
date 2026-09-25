import Foundation

/// Validated destinations shared by pasted links, incoming URLs, and comment links.
enum Deeplinker {
    enum Deeplink: Equatable {
        case board(name: String)
        case thread(board: String, id: String, postID: Int? = nil)
        case post(id: String)
    }

    static func parse(_ text: String) -> Deeplink? {
        var text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.lowercased().hasPrefix("boards.4chan.org/") || text.lowercased().hasPrefix("boards.4channel.org/") {
            text = "https://" + text
        }
        guard let url = URL(string: text) else { return nil }
        return getType(url: url)
    }

    static func getType(url: URL) -> Deeplink? {
        guard url.user == nil, url.password == nil, url.port == nil else { return nil }
        if url.scheme?.lowercased() == URL.appScheme {
            return customLink(url)
        }
        guard ["https", "http"].contains(url.scheme?.lowercased() ?? ""),
              ["boards.4chan.org", "boards.4channel.org"].contains(url.host?.lowercased() ?? "") else { return nil }
        let parts = url.path.split(separator: "/").map(String.init)
        guard let first = parts.first, let board = normalizedBoard(first) else { return nil }
        if parts.count == 1 || (parts.count == 2 && (parts[1] == "catalog" || Int(parts[1]).map { $0 >= 0 } == true)) {
            return .board(name: board)
        }
        guard (3...4).contains(parts.count), parts[1] == "thread", let id = positiveID(parts[2]) else { return nil }
        var postID: Int?
        if let fragment = url.fragment, !fragment.isEmpty {
            guard fragment.hasPrefix("p"), let parsed = positiveID(String(fragment.dropFirst())) else { return nil }
            postID = parsed
        }
        return .thread(board: board, id: String(id), postID: postID)
    }

    static func normalizedBoard(_ text: String) -> String? {
        let name = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/")).lowercased()
        guard !name.isEmpty, name.utf8.allSatisfy({ (97...122).contains($0) || (48...57).contains($0) }) else { return nil }
        return name
    }

    private static func positiveID(_ text: String) -> Int? {
        guard !text.isEmpty, text.utf8.allSatisfy({ (48...57).contains($0) }), let id = Int(text), id > 0 else { return nil }
        return id
    }

    private static func customLink(_ url: URL) -> Deeplink? {
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        func value(_ name: String) -> String? {
            let matches = items.filter { $0.name == name }
            return matches.count == 1 ? matches.first?.value : nil
        }
        let route = url.host.map { "/" + $0 } ?? url.path
        switch route {
        case "/board":
            guard let name = value("name").flatMap(normalizedBoard) else { return nil }
            return .board(name: name)
        case "/thread":
            guard let board = value("board").flatMap(normalizedBoard), let id = value("id").flatMap(positiveID) else { return nil }
            return .thread(board: board, id: String(id))
        case "/reply":
            guard let id = value("id").flatMap(positiveID) else { return nil }
            return .post(id: String(id))
        default:
            return nil
        }
    }
}
