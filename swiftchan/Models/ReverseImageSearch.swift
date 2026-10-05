import Foundation

enum ReverseImageSearchProvider: String, CaseIterable, Identifiable {
    case googleLens, yandex, tineye, sauceNAO, iqdb, traceMoe

    var id: String { rawValue }

    var name: String {
        switch self {
        case .googleLens: "Google Lens"
        case .yandex: "Yandex"
        case .tineye: "TinEye"
        case .sauceNAO: "SauceNAO"
        case .iqdb: "IQDB"
        case .traceMoe: "trace.moe"
        }
    }

    func searchURL(for media: Media) -> URL? {
        guard let imageURL = Self.sourceURL(for: media) else { return nil }
        let endpoint: String
        switch self {
        case .googleLens: endpoint = "https://lens.google.com/uploadbyurl"
        case .yandex: endpoint = "https://yandex.com/images/search"
        case .tineye: endpoint = "https://tineye.com/search"
        case .sauceNAO: endpoint = "https://saucenao.com/search.php"
        case .iqdb: endpoint = "https://iqdb.org/"
        case .traceMoe: endpoint = "https://trace.moe/"
        }
        var components = URLComponents(string: endpoint)
        var items: [URLQueryItem] = []
        if self == .yandex { items.append(URLQueryItem(name: "rpt", value: "imageview")) }
        items.append(URLQueryItem(name: "url", value: imageURL.absoluteString))
        components?.queryItems = items
        // These providers parse form-style queries, where an unescaped + means a space.
        let encodedQuery = components?.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        components?.percentEncodedQuery = encodedQuery
        return components?.url
    }

    static func sourceURL(for media: Media) -> URL? {
        let source: URL
        switch media.url.pathExtension.lowercased() {
        case "jpg", "jpeg", "png", "gif": source = media.url
        case "webm", "mp4": source = media.thumbnailUrl
        default: return nil
        }
        guard ["http", "https"].contains(source.scheme?.lowercased() ?? ""),
              let host = source.host, !host.isEmpty, source.user == nil, source.password == nil else { return nil }
        return source
    }

    static func usesThumbnail(for media: Media) -> Bool {
        ["webm", "mp4"].contains(media.url.pathExtension.lowercased())
    }
}
