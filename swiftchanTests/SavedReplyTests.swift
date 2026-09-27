import XCTest
import SwiftData
@testable import swiftchan

@MainActor
final class SavedReplyTests: XCTestCase {
    func testBackupRoundTripKeepsReplyTextAndSkipsExistingBookmarks() throws {
        let container = try FavoritesStore.makeContainer(configuration: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        context.insert(SavedReply(boardName: "biz", threadID: 100, postID: 105, threadTitle: "Metals", text: "Original", savedAt: date))
        try context.save()
        let exported = try FavoritesBackupStore.export(from: context)
        XCTAssertEqual(exported.version, 2)
        let decoded = try FavoritesBackup.decode(exported.encoded())
        XCTAssertEqual(decoded.replies?.first?.text, "Original")
        XCTAssertEqual(decoded.replies?.first?.savedAt, date)
        let destination = try FavoritesStore.makeContainer(configuration: ModelConfiguration(isStoredInMemoryOnly: true))
        let target = ModelContext(destination)
        XCTAssertEqual(try FavoritesBackupStore.restore(decoded, in: target).replies.count, 1)
        XCTAssertEqual(try FavoritesBackupStore.restore(decoded, in: target).skipped, 1)
        let saved = try XCTUnwrap(target.fetch(FetchDescriptor<SavedReply>()).first)
        XCTAssertEqual(saved.text, "Original")
        XCTAssertEqual(saved.url.absoluteString, "https://boards.4chan.org/biz/thread/100#p105")
    }

    func testBackupRejectsInvalidReplyBeforeInsertingAnything() throws {
        let container = try FavoritesStore.makeContainer(configuration: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let backup = FavoritesBackup(threads: [], generals: [], replies: [
            .init(board: "biz", threadID: 100, postID: 105, title: "Valid", text: "Saved", savedAt: Date()),
            .init(board: "biz", threadID: 100, postID: -1, title: "Invalid", text: "", savedAt: Date())
        ])
        XCTAssertThrowsError(try FavoritesBackupStore.restore(backup, in: context))
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<SavedReply>()), 0)
    }

    func testV2MigrationPreservesFavoritesAndPersistsBoardScopedReplies() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("favorites.store")
        try autoreleasepool {
            let old = try ModelContainer(for: Schema(versionedSchema: FavoritesSchemaV2.self), configurations: ModelConfiguration(url: url))
            let context = ModelContext(old)
            context.insert(FavoriteThread(threadId: 100, boardName: "biz", title: "Metals", createdTime: .distantPast))
            context.insert(RecurringFavorite(searchPattern: "/pmg/", boardName: "biz", displayName: "My metals"))
            try context.save()
        }
        try autoreleasepool {
            let container = try FavoritesStore.makeContainer(configuration: ModelConfiguration(url: url))
            let context = ModelContext(container)
            XCTAssertEqual(try context.fetch(FetchDescriptor<FavoriteThread>()).first?.title, "Metals")
            XCTAssertEqual(try context.fetch(FetchDescriptor<RecurringFavorite>()).first?.displayName, "My metals")
            for board in ["biz", "g"] {
                context.insert(SavedReply(boardName: board, threadID: 100, postID: 105, threadTitle: "Title", text: "Snapshot"))
            }
            try context.save()
        }
        try autoreleasepool {
            let container = try FavoritesStore.makeContainer(configuration: ModelConfiguration(url: url))
            let context = ModelContext(container)
            let replies = try context.fetch(FetchDescriptor<SavedReply>())
            XCTAssertEqual(Set(replies.map(\.boardName)), ["biz", "g"])
            XCTAssertTrue(replies.allSatisfy { $0.text == "Snapshot" })
        }
    }
}
