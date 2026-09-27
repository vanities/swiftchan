import Foundation
import SwiftData

@MainActor
enum FavoritesBackupStore {
    static func export(from context: ModelContext) throws -> FavoritesBackup {
        let threads = try context.fetch(FetchDescriptor<FavoriteThread>(sortBy: [SortDescriptor(\.savedAt)]))
        let generals = try context.fetch(FetchDescriptor<RecurringFavorite>(sortBy: [SortDescriptor(\.createdAt)]))
        return FavoritesBackup(threads: threads.map {
            .init(board: $0.boardName, number: $0.threadId, title: $0.title, createdAt: $0.createdTime, savedAt: $0.savedAt)
        }, generals: generals.map {
            .init(board: $0.boardName, tag: $0.searchPattern, name: $0.displayName, createdAt: $0.createdAt)
        })
    }

    static func restore(_ backup: FavoritesBackup, in context: ModelContext) throws -> FavoritesBackup.ImportPlan {
        let existing = try export(from: context).validated()
        let plan = try backup.importPlan(threadKeys: Set(existing.threads.map(\.key)), generalKeys: Set(existing.generals.map(\.key)))
        var insertedThreads: [FavoriteThread] = []
        var insertedGenerals: [RecurringFavorite] = []
        for record in plan.threads {
            let thread = FavoriteThread(threadId: record.number, boardName: record.board, title: record.title,
                                        createdTime: record.createdAt, savedAt: record.savedAt)
            context.insert(thread)
            insertedThreads.append(thread)
        }
        for record in plan.generals {
            let general = RecurringFavorite(searchPattern: record.tag, boardName: record.board, displayName: record.name)
            general.createdAt = record.createdAt
            context.insert(general)
            insertedGenerals.append(general)
        }
        do {
            if !insertedThreads.isEmpty || !insertedGenerals.isEmpty { try context.save() }
            return plan
        } catch {
            // Remove only this import's inserts; preserve unrelated edits in the shared context.
            insertedThreads.forEach { context.delete($0) }
            insertedGenerals.forEach { context.delete($0) }
            throw error
        }
    }
}
