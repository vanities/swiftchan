//
//  RecurringFavorite.swift
//  swiftchan
//
//  SwiftData model for recurring thread favorites.
//  Stores a search pattern that can be used to find the latest matching thread.
//

import Foundation
import SwiftData

@Model
final class RecurringFavorite {
    @Attribute(.unique) var id: UUID
    var searchPattern: String
    var boardName: String
    var displayName: String?
    var createdAt: Date
    var lastMatchedAt: Date?
    var lastMatchCount: Int
    var lastThumbnailUrlString: String?

    var effectiveDisplayName: String {
        displayName ?? searchPattern
    }

    var lastThumbnailUrl: URL? {
        guard let urlString = lastThumbnailUrlString else { return nil }
        return URL(string: urlString)
    }

    init(
        searchPattern: String,
        boardName: String,
        displayName: String? = nil
    ) {
        self.id = UUID()
        self.searchPattern = searchPattern
        self.boardName = boardName
        self.displayName = displayName
        self.createdAt = Date()
        self.lastMatchCount = 0
    }
}

/// The form and catalog shortcut use the same normalization and duplicate rules.
struct RecurringFavoriteDraft {
    let boardName: String
    let searchPattern: String
    let displayName: String?

    init?(boardName: String, searchPattern: String, displayName: String) {
        guard let board = Deeplinker.normalizedBoard(boardName) else { return nil }
        let tag = searchPattern.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/")).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !tag.isEmpty, !tag.contains("/"), !tag.contains("\n") else { return nil }
        self.boardName = board
        self.searchPattern = "/\(tag.lowercased())/"
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.displayName = name.isEmpty ? nil : name
    }

    @MainActor
    func save(in context: ModelContext, editing: RecurringFavorite? = nil) throws -> RecurringFavorite {
        let existing = try context.fetch(FetchDescriptor<RecurringFavorite>()).first {
            Self(boardName: $0.boardName, searchPattern: $0.searchPattern, displayName: "").map {
                $0.boardName == boardName && $0.searchPattern == searchPattern
            } == true
        }
        if let editing, let existing, editing.id != existing.id {
            throw SaveError.alreadyFollowed
        }
        let target = editing ?? existing ?? RecurringFavorite(searchPattern: searchPattern, boardName: boardName)
        let isNew = editing == nil && existing == nil
        let previous = (target.boardName, target.searchPattern, target.displayName, target.lastMatchedAt,
                        target.lastMatchCount, target.lastThumbnailUrlString)
        if target.boardName != boardName || target.searchPattern != searchPattern {
            target.lastMatchedAt = nil
            target.lastMatchCount = 0
            target.lastThumbnailUrlString = nil
        }
        target.boardName = boardName
        target.searchPattern = searchPattern
        // Re-following from catalog search should retain a name already chosen in Favorites.
        if isNew || editing != nil || displayName != nil { target.displayName = displayName }
        if isNew { context.insert(target) }
        do {
            try context.save()
            return target
        } catch {
            if isNew { context.delete(target) }
            (target.boardName, target.searchPattern, target.displayName, target.lastMatchedAt,
             target.lastMatchCount, target.lastThumbnailUrlString) = previous
            throw error
        }
    }

    enum SaveError: LocalizedError {
        case alreadyFollowed
        var errorDescription: String? { "You already follow this general on that board. Edit its existing entry instead." }
    }
}
