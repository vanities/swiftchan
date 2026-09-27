import Foundation
import SwiftData

@MainActor
enum FavoritesBackupStore {
    static func export(from context: ModelContext) throws -> FavoritesBackup {
        let threads = try context.fetch(FetchDescriptor<FavoriteThread>(sortBy: [SortDescriptor(\.savedAt)]))
        let generals = try context.fetch(FetchDescriptor<RecurringFavorite>(sortBy: [SortDescriptor(\.createdAt)]))
        let replies = try context.fetch(FetchDescriptor<SavedReply>(sortBy: [SortDescriptor(\.savedAt)]))
        return FavoritesBackup(threads: threads.map {
            .init(board: $0.boardName, number: $0.threadId, title: $0.title, createdAt: $0.createdTime, savedAt: $0.savedAt)
        }, generals: generals.map {
            .init(board: $0.boardName, tag: $0.searchPattern, name: $0.displayName, createdAt: $0.createdAt)
        }, replies: replies.map {
            .init(board: $0.boardName, threadID: $0.threadID, postID: $0.postID, title: $0.threadTitle, text: $0.text, savedAt: $0.savedAt)
        })
    }

    static func restore(_ backup: FavoritesBackup, in context: ModelContext) throws -> FavoritesBackup.ImportPlan {
        let existing = try export(from: context).validated()
        let plan = try backup.importPlan(threadKeys: Set(existing.threads.map(\.key)), generalKeys: Set(existing.generals.map(\.key)),
                                         replyKeys: Set((existing.replies ?? []).map(\.key)))
        var insertedThreads: [FavoriteThread] = []
        var insertedGenerals: [RecurringFavorite] = []
        var insertedReplies: [SavedReply] = []
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
        for record in plan.replies {
            let reply = SavedReply(boardName: record.board, threadID: record.threadID, postID: record.postID,
                                   threadTitle: record.title, text: record.text, savedAt: record.savedAt)
            context.insert(reply)
            insertedReplies.append(reply)
        }
        do {
            if !insertedThreads.isEmpty || !insertedGenerals.isEmpty || !insertedReplies.isEmpty { try context.save() }
            return plan
        } catch {
            // Remove only this import's inserts; preserve unrelated edits in the shared context.
            insertedThreads.forEach { context.delete($0) }
            insertedGenerals.forEach { context.delete($0) }
            insertedReplies.forEach { context.delete($0) }
            throw error
        }
    }
}
