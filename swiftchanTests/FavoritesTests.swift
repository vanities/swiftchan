import XCTest
import SwiftData
@testable import swiftchan

@MainActor
final class FavoritesTests: XCTestCase {
    func testEachSortOptionRespectsDirection() {
        let earlier = FavoriteThread(threadId: 1, boardName: "po", title: "Paper", replyCount: 2, imageCount: 1,
                                     createdTime: .distantPast, savedAt: .distantPast)
        let later = FavoriteThread(threadId: 2, boardName: "tg", title: "Games", replyCount: 9, imageCount: 5,
                                   createdTime: .distantFuture, savedAt: .distantFuture)
        for sort in FavoriteSortOption.allCases {
            XCTAssertEqual(FavoritesQuery(sort: sort, ascending: true).savedThreads([later, earlier]).map(\.threadId), [1, 2], sort.rawValue)
            XCTAssertEqual(FavoritesQuery(sort: sort, ascending: false).savedThreads([earlier, later]).map(\.threadId), [2, 1], sort.rawValue)
        }
    }

    func testEqualSortValuesUseStrictStableIdentityOrdering() {
        let lhs = FavoriteThread(threadId: 1, boardName: "po", title: "One", createdTime: .distantPast, savedAt: .distantPast)
        let rhs = FavoriteThread(threadId: 2, boardName: "po", title: "Two", createdTime: .distantPast, savedAt: .distantPast)
        for sort in FavoriteSortOption.allCases {
            for ascending in [true, false] {
                let query = FavoritesQuery(sort: sort, ascending: ascending)
                XCTAssertFalse(query.precedes(lhs, lhs))
                XCTAssertNotEqual(query.precedes(lhs, rhs), query.precedes(rhs, lhs))
                XCTAssertEqual(query.savedThreads([rhs, lhs]).map(\.threadId), [1, 2])
            }
        }
    }

    func testBoardFilterAppliesToRecurringFavoritesAlongsideSearch() {
        let paper = RecurringFavorite(searchPattern: "general", boardName: "po")
        let games = RecurringFavorite(searchPattern: "general", boardName: "tg")
        XCTAssertEqual(FavoritesQuery(boardName: "po").recurringThreads([paper, games]).map(\.boardName), ["po"])
        XCTAssertEqual(FavoritesQuery(searchText: "general", boardName: "po").recurringThreads([paper, games]).map(\.boardName), ["po"])
        XCTAssertTrue(FavoritesQuery(searchText: "other", boardName: "po").recurringThreads([paper, games]).isEmpty)
        XCTAssertEqual(FavoritesQuery().recurringThreads([paper, games]).count, 2)
    }

    func testBoardChoicesIncludeRecurringOnlyBoardsWithoutDuplicates() {
        let saved = FavoriteThread(threadId: 1, boardName: "po", title: "Paper", createdTime: .distantPast)
        let recurring = [RecurringFavorite(searchPattern: "general", boardName: "tg"),
                         RecurringFavorite(searchPattern: "origami", boardName: "po")]
        XCTAssertEqual(FavoritesQuery.availableBoards(saved: [saved], recurring: recurring), ["po", "tg"])
    }

    func testSameThreadNumberCanBeSavedOnDifferentBoards() throws {
        let container = try ModelContainer(for: FavoriteThread.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        context.insert(FavoriteThread(threadId: 123, boardName: "po", title: "Paper", createdTime: .distantPast))
        try context.save()
        context.insert(FavoriteThread(threadId: 123, boardName: "tg", title: "Games", createdTime: .distantPast))
        try context.save()

        let saved = try context.fetch(FetchDescriptor<FavoriteThread>())
        XCTAssertEqual(saved.count, 2)
        XCTAssertEqual(Set(saved.map(\.boardName)), ["po", "tg"])
    }

    func testLegacyStoreMigrationPreservesFavoritesAndAllowsCrossBoardIDs() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("default.store")
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let recurringID = UUID()

        // Match the previously shipped, unversioned container rather than starting at V2.
        try autoreleasepool {
            let container = try ModelContainer(for: Schema(FavoritesSchemaV1.models), configurations: ModelConfiguration(url: url))
            let context = ModelContext(container)
            context.insert(FavoritesSchemaV1.FavoriteThread(threadId: 123, boardName: "po", title: "Paper",
                                                           thumbnailUrlString: "https://example.com/thumb.jpg", replyCount: 7,
                                                           imageCount: 3, createdTime: date, savedAt: date))
            let recurring = FavoritesSchemaV1.RecurringFavorite(searchPattern: "origami", boardName: "po", displayName: "Paper folding")
            recurring.id = recurringID
            recurring.createdAt = date
            recurring.lastMatchedAt = date
            recurring.lastMatchCount = 4
            recurring.lastThumbnailUrlString = "https://example.com/recurring.jpg"
            context.insert(recurring)
            try context.save()
        }

        try autoreleasepool {
            let container = try FavoritesStore.makeContainer(configuration: ModelConfiguration(url: url))
            let context = ModelContext(container)
            try assertMigratedFields(context, date: date, recurringID: recurringID)
            context.insert(FavoriteThread(threadId: 123, boardName: "tg", title: "Games", createdTime: date))
            try context.save()
        }

        try autoreleasepool {
            let container = try FavoritesStore.makeContainer(configuration: ModelConfiguration(url: url))
            let context = ModelContext(container)
            let saved = try context.fetch(FetchDescriptor<FavoriteThread>())
            XCTAssertEqual(saved.count, 2)
            XCTAssertEqual(Set(saved.map(\.boardName)), ["po", "tg"])
            context.insert(FavoriteThread(threadId: 123, boardName: "po", title: "Updated paper", createdTime: date))
            try context.save()
        }

        let container = try FavoritesStore.makeContainer(configuration: ModelConfiguration(url: url))
        let context = ModelContext(container)
        let saved = try context.fetch(FetchDescriptor<FavoriteThread>())
        XCTAssertEqual(saved.count, 2)
        XCTAssertEqual(saved.first { $0.boardName == "po" }?.title, "Updated paper")
        XCTAssertEqual(saved.first { $0.boardName == "tg" }?.title, "Games")
    }

    private func assertMigratedFields(_ context: ModelContext, date: Date, recurringID: UUID) throws {
        let saved = try XCTUnwrap(context.fetch(FetchDescriptor<FavoriteThread>()).first)
        XCTAssertEqual(saved.threadId, 123)
        XCTAssertEqual(saved.boardName, "po")
        XCTAssertEqual(saved.title, "Paper")
        XCTAssertEqual(saved.thumbnailUrlString, "https://example.com/thumb.jpg")
        XCTAssertEqual(saved.replyCount, 7)
        XCTAssertEqual(saved.imageCount, 3)
        XCTAssertEqual(saved.createdTime, date)
        XCTAssertEqual(saved.savedAt, date)
        let recurring = try XCTUnwrap(context.fetch(FetchDescriptor<RecurringFavorite>()).first)
        XCTAssertEqual(recurring.id, recurringID)
        XCTAssertEqual(recurring.searchPattern, "origami")
        XCTAssertEqual(recurring.boardName, "po")
        XCTAssertEqual(recurring.displayName, "Paper folding")
        XCTAssertEqual(recurring.createdAt, date)
        XCTAssertEqual(recurring.lastMatchedAt, date)
        XCTAssertEqual(recurring.lastMatchCount, 4)
        XCTAssertEqual(recurring.lastThumbnailUrlString, "https://example.com/recurring.jpg")
    }
}
