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

    func findMatches(for favorite: RecurringFavorite) async {
        state = .loading

        do {
            let catalog = try await FourChanAsyncService.shared.getCatalog(boardName: favorite.boardName)

            var allPosts: [SwiftchanPost] = []
            var index = 0

            for page in catalog {
                for thread in page.threads {
                    let comment: AttributedString
                    if let com = thread.com {
                        comment = CommentParser(comment: com).getComment()
                    } else {
                        comment = AttributedString()
                    }
                    allPosts.append(SwiftchanPost(post: thread, boardName: favorite.boardName, comment: comment, index: index))
                    index += 1
                }
            }

            let matches = filterPosts(allPosts, pattern: favorite.searchPattern)

            favorite.lastMatchedAt = Date()
            favorite.lastMatchCount = matches.count

            // Save the thumbnail of the most recent match
            if let firstMatch = matches.first {
                favorite.lastThumbnailUrlString = firstMatch.post.getMediaUrl(boardId: favorite.boardName, thumbnail: true)?.absoluteString
            }

            switch matches.count {
            case 0:
                state = .noMatches
            case 1:
                state = .singleMatch(matches[0])
            default:
                state = .multipleMatches(matches)
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    private func filterPosts(_ posts: [SwiftchanPost], pattern: String) -> [SwiftchanPost] {
        let searchPattern = pattern.lowercased()

        // Only match against the OP title (subject)
        let filtered = posts.filter { swiftChanPost in
            let subject = swiftChanPost.post.sub?.clean.lowercased() ?? ""
            return subject.contains(searchPattern)
        }

        return filtered.sorted { $0.post.no > $1.post.no }
    }

    func reset() {
        state = .idle
    }
}
