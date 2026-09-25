import Foundation

enum FavoriteSortOption: String, CaseIterable {
    case savedAt = "Date Saved"
    case boardName = "Board"
    case replyCount = "Replies"
    case imageCount = "Images"
}

/// The selection rules shared by the saved and recurring sections of Favorites.
struct FavoritesQuery {
    var searchText = ""
    var boardName: String?
    var sort: FavoriteSortOption = .savedAt
    var ascending = false

    static func availableBoards(saved: [FavoriteThread], recurring: [RecurringFavorite]) -> [String] {
        Array(Set(saved.map(\.boardName) + recurring.map(\.boardName))).sorted()
    }

    func savedThreads(_ favorites: [FavoriteThread]) -> [FavoriteThread] {
        favorites.filter { favorite in
            (boardName == nil || favorite.boardName == boardName) &&
            (searchText.isEmpty || favorite.title.localizedCaseInsensitiveContains(searchText) ||
             favorite.boardName.localizedCaseInsensitiveContains(searchText) || String(favorite.threadId).contains(searchText))
        }.sorted(by: precedes)
    }

    func recurringThreads(_ favorites: [RecurringFavorite]) -> [RecurringFavorite] {
        favorites.filter { favorite in
            (boardName == nil || favorite.boardName == boardName) &&
            (searchText.isEmpty || favorite.searchPattern.localizedCaseInsensitiveContains(searchText) ||
            favorite.boardName.localizedCaseInsensitiveContains(searchText) ||
            (favorite.displayName?.localizedCaseInsensitiveContains(searchText) ?? false))
        }
    }

    func precedes(_ lhs: FavoriteThread, _ rhs: FavoriteThread) -> Bool {
        switch sort {
        case .savedAt where lhs.savedAt != rhs.savedAt:
            return ascending ? lhs.savedAt < rhs.savedAt : lhs.savedAt > rhs.savedAt
        case .boardName where lhs.boardName != rhs.boardName:
            return ascending ? lhs.boardName < rhs.boardName : lhs.boardName > rhs.boardName
        case .replyCount where lhs.replyCount != rhs.replyCount:
            return ascending ? lhs.replyCount < rhs.replyCount : lhs.replyCount > rhs.replyCount
        case .imageCount where lhs.imageCount != rhs.imageCount:
            return ascending ? lhs.imageCount < rhs.imageCount : lhs.imageCount > rhs.imageCount
        default:
            // A stable tie-breaker keeps equal values from jumping around when the order changes.
            return (lhs.boardName, lhs.threadId) < (rhs.boardName, rhs.threadId)
        }
    }
}
