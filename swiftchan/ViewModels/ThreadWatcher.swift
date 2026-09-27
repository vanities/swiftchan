import Foundation
import Observation
import FourChan

struct WatchTarget: Identifiable {
    let board: String
    let threadID: Int
    var id: String { "\(board)/\(threadID)" }
}

struct WatchedThread {
    let replyIDs: [Int]
    let archived: Bool
    let missing: Bool
    var lastModified: String?

    func unread(after highestReadID: Int?) -> Int? {
        highestReadID.map { boundary in replyIDs.filter { $0 > boundary }.count }
    }
}

@Observable @MainActor
final class ThreadWatcher {
    enum Update { case changed(WatchedThread), unchanged }
    typealias Loader = (WatchTarget, String?) async throws -> Update
    static let shared = ThreadWatcher()
    private(set) var results: [String: WatchedThread] = [:]
    private(set) var errors: [String: String] = [:]
    private(set) var refreshing = false
    private(set) var checkedAt: Date?
    @ObservationIgnored private let loader: Loader
    @ObservationIgnored private var lastAttempt: Date?
    @ObservationIgnored private var lastRequest: Date?
    @ObservationIgnored private let interval: TimeInterval
    @ObservationIgnored private var cancelled = false

    init(interval: TimeInterval = 30, loader: @escaping Loader = ThreadWatcher.fetch) {
        self.interval = interval
        self.loader = loader
    }

    func refresh(_ targets: [WatchTarget]) async {
        guard !refreshing, lastAttempt.map({ Date().timeIntervalSince($0) >= interval }) ?? true else { return }
        refreshing = true
        cancelled = false
        lastAttempt = Date()
        defer { refreshing = false }
        let keys = Set(targets.map(\.id))
        results = results.filter { keys.contains($0.key) }
        errors = errors.filter { keys.contains($0.key) }
        for target in targets {
            do {
                if interval > 0, let lastRequest {
                    let wait = max(0, 1.1 - Date().timeIntervalSince(lastRequest))
                    try await Task.sleep(for: .seconds(wait))
                }
                try Task.checkCancellation()
                guard !cancelled else { return }
                lastRequest = Date()
                let update = try await loader(target, results[target.id]?.lastModified)
                try Task.checkCancellation()
                guard !cancelled else { return }
                if case .changed(let value) = update { results[target.id] = value }
                errors[target.id] = nil
            } catch {
                if Task.isCancelled || error is CancellationError { return }
                errors[target.id] = "Couldn’t refresh"
            }
        }
        checkedAt = Date()
    }

    func cancel() { cancelled = true }

    private static func fetch(_ target: WatchTarget, lastModified: String?) async throws -> Update {
        #if DEBUG
        if let thread = try ThreadUITestFixture.load(board: target.board, id: target.threadID) {
            return .changed(WatchedThread(replyIDs: thread.posts.dropFirst().map(\.no), archived: false, missing: false))
        }
        #endif
        guard let board = Deeplinker.normalizedBoard(target.board), target.threadID > 0,
              let url = URL(string: "https://a.4cdn.org/\(board)/thread/\(target.threadID).json") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue(lastModified, forHTTPHeaderField: "If-Modified-Since")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if response.statusCode == 304 { return .unchanged }
        if response.statusCode == 404 { return .changed(WatchedThread(replyIDs: [], archived: false, missing: true)) }
        guard response.statusCode == 200 else { throw URLError(.badServerResponse) }
        let thread = try JSONDecoder().decode(ChanThread.self, from: data)
        guard let first = thread.posts.first else { throw URLError(.cannotParseResponse) }
        return .changed(WatchedThread(replyIDs: thread.posts.dropFirst().map(\.no), archived: first.archived == 1,
                                      missing: false, lastModified: response.value(forHTTPHeaderField: "Last-Modified")))
    }
}
