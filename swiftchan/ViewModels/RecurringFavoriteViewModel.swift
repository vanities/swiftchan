//
//  RecurringFavoriteViewModel.swift
//  swiftchan
//
//  ViewModel for finding matching threads for recurring favorites.
//

import SwiftUI
import FourChan

@Observable @MainActor
class RecurringFavoriteViewModel {
    typealias CatalogLoader = (String) async throws -> Catalog
    @ObservationIgnored private let fetchCatalog: CatalogLoader
    @ObservationIgnored private let parseComment: (String) -> AttributedString
    @ObservationIgnored private var activeRequest: UUID?

    init(fetchCatalog: @escaping CatalogLoader = {
        #if DEBUG
        if let catalog = try ThreadUITestFixture.catalog(board: $0) { return catalog }
        #endif
        return try await FourChanAsyncService.shared.getCatalog(boardName: $0)
    },
         parseComment: @escaping (String) -> AttributedString = { CommentParser(comment: $0).getComment() }) {
        self.fetchCatalog = fetchCatalog
        self.parseComment = parseComment
    }

    enum MatchState: Equatable {
        case idle
        case loading
        case noMatches
        case singleMatch(SwiftchanPost)
        case multipleMatches([SwiftchanPost])
        case error(String)

        static func == (lhs: MatchState, rhs: MatchState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.loading, .loading), (.noMatches, .noMatches):
                return true
            case let (.singleMatch(a), .singleMatch(b)):
                return a.id == b.id
            case let (.multipleMatches(a), .multipleMatches(b)):
                return a.map { $0.id } == b.map { $0.id }
            case let (.error(a), .error(b)):
                return a == b
            default:
                return false
            }
        }
    }

    var state: MatchState = .idle

    func findMatches(for favorite: RecurringFavorite, excludingThreadID: Int? = nil) async {
        let request = UUID()
        activeRequest = request
        state = .loading

        do {
            let catalog = try await fetchCatalog(favorite.boardName)
            guard activeRequest == request else { return }
            try Task.checkCancellation()

            let pattern = favorite.searchPattern.lowercased()
            // Filter cheap title strings before parsing rich comments for the matching threads.
            let matchingThreads = catalog.flatMap(\.threads).enumerated().filter {
                $0.element.no > (excludingThreadID ?? 0) && ($0.element.sub?.clean.lowercased() ?? "").contains(pattern)
            }.sorted { $0.element.no > $1.element.no }
            let matches = matchingThreads.map { index, thread in
                SwiftchanPost(post: thread, boardName: favorite.boardName,
                              comment: thread.com.map(parseComment) ?? AttributedString(), index: index)
            }

            favorite.lastMatchedAt = Date()
            favorite.lastMatchCount = matches.count

            // Save the thumbnail of the most recent match
            favorite.lastThumbnailUrlString = matches.first?.post.getMediaUrl(boardId: favorite.boardName, thumbnail: true)?.absoluteString

            switch matches.count {
            case 0:
                state = .noMatches
            case 1:
                state = .singleMatch(matches[0])
            default:
                state = .multipleMatches(matches)
            }
        } catch {
            guard activeRequest == request else { return }
            if error is CancellationError || (error as? URLError)?.code == .cancelled {
                state = .idle
            } else {
                state = .error(error.localizedDescription)
            }
        }
    }

    func reset() {
        activeRequest = nil
        state = .idle
    }
}
