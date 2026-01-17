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
