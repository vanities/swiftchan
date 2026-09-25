import Foundation

struct GeneralSuggestion: Equatable {
    let tag: String
    let name: String

    /// Recognize explicit slash-delimited tags, never arbitrary words or URL path segments.
    init?(title: String) {
        guard let expression = try? NSRegularExpression(pattern: #"(?:^|\s)/([A-Za-z0-9][A-Za-z0-9_-]{0,31})/(?=\s|$|[-–—:])"#),
              let match = expression.firstMatch(in: title, range: NSRange(title.startIndex..., in: title)),
              let tagRange = Range(match.range(at: 1), in: title),
              let fullRange = Range(match.range, in: title) else { return nil }
        tag = "/\(title[tagRange].lowercased())/"
        var name = title
        name.removeSubrange(fullRange)
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-–—:| "))
    }
}
