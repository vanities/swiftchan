import Foundation
import SwiftData

/// Frozen copies of the schema shipped before board-scoped favorite identity.
/// Keep these definitions unchanged so existing unversioned stores can be recognized.
enum FavoritesSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
    static var models: [any PersistentModel.Type] { [FavoriteThread.self, RecurringFavorite.self] }

    @Model
    final class FavoriteThread {
        @Attribute(.unique) var threadId: Int
        var boardName: String
        var title: String
        var thumbnailUrlString: String?
        var replyCount: Int
        var imageCount: Int
        var createdTime: Date
        var savedAt: Date

        var thumbnailUrl: URL? {
            guard let urlString = thumbnailUrlString else { return nil }
            return URL(string: urlString)
        }

        init(
            threadId: Int,
            boardName: String,
            title: String,
            thumbnailUrlString: String? = nil,
            replyCount: Int = 0,
            imageCount: Int = 0,
            createdTime: Date,
            savedAt: Date = Date()
        ) {
            self.threadId = threadId
            self.boardName = boardName
            self.title = title
            self.thumbnailUrlString = thumbnailUrlString
            self.replyCount = replyCount
            self.imageCount = imageCount
            self.createdTime = createdTime
            self.savedAt = savedAt
        }
    }

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
}

enum FavoritesSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }
    static var models: [any PersistentModel.Type] { [FavoriteThread.self, RecurringFavorite.self] }
}

enum FavoritesMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [FavoritesSchemaV1.self, FavoritesSchemaV2.self] }
    static var stages: [MigrationStage] {
        // V1's globally unique thread IDs already guarantee unique (board, thread) pairs.
        // No rows need to be discarded when replacing that constraint.
        [.custom(fromVersion: FavoritesSchemaV1.self, toVersion: FavoritesSchemaV2.self,
                 willMigrate: nil, didMigrate: nil)]
    }
}

@MainActor
enum FavoritesStore {
    static func makeContainer(configuration: ModelConfiguration = ModelConfiguration()) throws -> ModelContainer {
        try ModelContainer(for: Schema(versionedSchema: FavoritesSchemaV2.self),
                           migrationPlan: FavoritesMigrationPlan.self, configurations: configuration)
    }
}
