import XCTest
import SwiftData
import FourChan
@testable import swiftchan

@MainActor
final class RecurringFavoriteTests: XCTestCase {
    func testGeneralRolloverOnlyOffersNewerMatchesAndKeepsName() async throws {
        let response = try catalog(#"[{"no":50,"sub":"/pmg/ old"},{"no":100,"sub":"/pmg/ current"},{"no":200,"sub":"/pmg/ next"},{"no":300,"sub":"Other"}]"#)
        let favorite = RecurringFavorite(searchPattern: "/pmg/", boardName: "biz", displayName: "My Metals")
        let model = RecurringFavoriteViewModel(fetchCatalog: { _ in response })
        await model.findMatches(for: favorite, excludingThreadID: 100)
        guard case .singleMatch(let post) = model.state else { return XCTFail("Expected the newer general") }
        XCTAssertEqual(post.id, 200)
        XCTAssertEqual(favorite.displayName, "My Metals")
    }

    func testPreciousMetalsFormNormalizesOptionalSlashesAndWhitespace() throws {
        let draft = try XCTUnwrap(RecurringFavoriteDraft(boardName: " /BIZ/ ", searchPattern: " PMG ", displayName: " Precious Metals General "))
        XCTAssertEqual(draft.boardName, "biz")
        XCTAssertEqual(draft.searchPattern, "/pmg/")
        XCTAssertEqual(draft.displayName, "Precious Metals General")
        XCTAssertNil(RecurringFavoriteDraft(boardName: "", searchPattern: "pmg", displayName: ""))
        XCTAssertNil(RecurringFavoriteDraft(boardName: "biz", searchPattern: "///", displayName: ""))
        XCTAssertNil(RecurringFavoriteDraft(boardName: "biz/tg", searchPattern: "pmg", displayName: ""))
    }

    func testFollowingAgainUpdatesNameWithoutCreatingDuplicate() throws {
        let container = try FavoritesStore.makeContainer(configuration: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let original = try XCTUnwrap(RecurringFavoriteDraft(boardName: "biz", searchPattern: "pmg", displayName: "")).save(in: context)
        original.lastMatchCount = 2
        let updated = try XCTUnwrap(RecurringFavoriteDraft(boardName: "/biz/", searchPattern: "/PMG/", displayName: "Precious Metals General")).save(in: context)
        XCTAssertEqual(original.id, updated.id)
        XCTAssertEqual(updated.displayName, "Precious Metals General")
        XCTAssertEqual(updated.lastMatchCount, 2)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<RecurringFavorite>()), 1)
    }

    func testRefollowingWithoutNameKeepsCustomNameButEditCanClearIt() throws {
        let container = try FavoritesStore.makeContainer(configuration: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let named = try XCTUnwrap(RecurringFavoriteDraft(boardName: "biz", searchPattern: "pmg", displayName: "Metals")).save(in: context)
        let draft = try XCTUnwrap(RecurringFavoriteDraft(boardName: "biz", searchPattern: "pmg", displayName: ""))
        _ = try draft.save(in: context)
        XCTAssertEqual(named.displayName, "Metals")
        _ = try draft.save(in: context, editing: named)
        XCTAssertNil(named.displayName)
    }

    func testSameGeneralOnAnotherBoardIsSeparateAndEditingPreservesIdentity() throws {
        let container = try FavoritesStore.makeContainer(configuration: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let first = try XCTUnwrap(RecurringFavoriteDraft(boardName: "biz", searchPattern: "pmg", displayName: "Metals")).save(in: context)
        _ = try XCTUnwrap(RecurringFavoriteDraft(boardName: "tg", searchPattern: "pmg", displayName: "")).save(in: context)
        first.lastMatchedAt = Date()
        first.lastMatchCount = 5
        let edited = try XCTUnwrap(RecurringFavoriteDraft(boardName: "biz", searchPattern: "new", displayName: "New General")).save(in: context, editing: first)
        XCTAssertEqual(first.id, edited.id)
        XCTAssertNil(edited.lastMatchedAt)
        XCTAssertEqual(edited.lastMatchCount, 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<RecurringFavorite>()), 2)
        XCTAssertThrowsError(try XCTUnwrap(RecurringFavoriteDraft(boardName: "tg", searchPattern: "pmg", displayName: "")).save(in: context, editing: first))
        XCTAssertEqual(first.boardName, "biz")
        XCTAssertEqual(first.searchPattern, "/new/")
    }

    func testMatchingUsesTitleAndSortsNewestFirst() async throws {
        let catalog = try catalog(#"[{"no":1,"sub":"/pmg/ old"},{"no":3,"sub":"/PMG/ Precious Metals General"},{"no":4,"sub":"other","com":"/pmg/"},{"no":2,"sub":"unrelated"}]"#)
        let model = RecurringFavoriteViewModel(fetchCatalog: { _ in catalog })
        let favorite = RecurringFavorite(searchPattern: "/pmg/", boardName: "biz")
        await model.findMatches(for: favorite)
        guard case .multipleMatches(let matches) = model.state else { return XCTFail("Expected multiple matches") }
        XCTAssertEqual(matches.map(\.id), [3, 1])
        XCTAssertEqual(favorite.lastMatchCount, 2)
        XCTAssertNotNil(favorite.lastMatchedAt)
    }

    func testOnlyMatchingCommentsAreParsedAndOriginalCatalogIndicesArePreserved() async throws {
        let response = try catalog(#"[{"no":1,"sub":"Other","com":"skip"},{"no":2,"sub":"/pmg/ old","com":"old"},{"no":3,"sub":"Other","com":"/pmg/ in body only"},{"no":4,"sub":"/PMG/ new","com":"new"}]"#)
        var parsed: [String] = []
        let model = RecurringFavoriteViewModel(fetchCatalog: { _ in response }, parseComment: {
            parsed.append($0)
            return AttributedString($0)
        })
        await model.findMatches(for: RecurringFavorite(searchPattern: "/pmg/", boardName: "biz"))
        guard case .multipleMatches(let matches) = model.state else { return XCTFail("Expected matching generals") }
        XCTAssertEqual(parsed.sorted(), ["new", "old"])
        XCTAssertEqual(matches.map(\.id), [4, 2])
        XCTAssertEqual(matches.map(\.index), [3, 1])
        XCTAssertEqual(matches.map { String($0.comment.characters) }, ["new", "old"])
    }

    func testNoMatchingTitlesDoesNotParseAnyComments() async throws {
        let response = try catalog(#"[{"no":1,"com":"/pmg/"},{"no":2,"sub":"Other","com":"skip"}]"#)
        let model = RecurringFavoriteViewModel(fetchCatalog: { _ in response }, parseComment: { _ in
            XCTFail("Unmatched catalog comments should not be parsed")
            return AttributedString()
        })
        await model.findMatches(for: RecurringFavorite(searchPattern: "/pmg/", boardName: "biz"))
        XCTAssertEqual(model.state, .noMatches)
    }

    func testCancelledLookupDoesNotPublishResultsOrChangeSavedMetadata() async throws {
        let response = try catalog(#"[{"no":1,"sub":"/pmg/"}]"#)
        var continuation: CheckedContinuation<Catalog, Error>?
        let entered = expectation(description: "loading")
        let model = RecurringFavoriteViewModel(fetchCatalog: { _ in
            try await withCheckedThrowingContinuation { continuation = $0; entered.fulfill() }
        })
        let favorite = RecurringFavorite(searchPattern: "/pmg/", boardName: "biz")
        let loading = Task { await model.findMatches(for: favorite) }
        await fulfillment(of: [entered], timeout: 2)
        model.reset()
        loading.cancel()
        continuation?.resume(returning: response)
        await loading.value
        XCTAssertEqual(model.state, .idle)
        XCTAssertNil(favorite.lastMatchedAt)
        XCTAssertEqual(favorite.lastMatchCount, 0)
    }

    func testOlderRequestCannotOverwriteNewerSearch() async throws {
        let old = try catalog(#"[{"no":1,"sub":"/pmg/"}]"#)
        let current = try catalog(#"[{"no":2,"sub":"/pmg/"}]"#)
        var continuation: CheckedContinuation<Catalog, Error>?
        let entered = expectation(description: "first request")
        var calls = 0
        let model = RecurringFavoriteViewModel(fetchCatalog: { _ in
            calls += 1
            if calls > 1 { return current }
            return try await withCheckedThrowingContinuation { continuation = $0; entered.fulfill() }
        })
        let first = RecurringFavorite(searchPattern: "/pmg/", boardName: "biz")
        let second = RecurringFavorite(searchPattern: "/pmg/", boardName: "tg")
        let pending = Task { await model.findMatches(for: first) }
        await fulfillment(of: [entered], timeout: 2)
        await model.findMatches(for: second)
        continuation?.resume(returning: old)
        await pending.value
        guard case .singleMatch(let match) = model.state else { return XCTFail("Expected latest match") }
        XCTAssertEqual(match.id, 2)
        XCTAssertNil(first.lastMatchedAt)
        XCTAssertNotNil(second.lastMatchedAt)
    }

    func testRetryRecoversAndNoMatchesClearsStaleThumbnail() async throws {
        let empty = try catalog("[]")
        var calls = 0
        let model = RecurringFavoriteViewModel(fetchCatalog: { _ in
            calls += 1
            if calls == 1 { throw URLError(.notConnectedToInternet) }
            return empty
        })
        let favorite = RecurringFavorite(searchPattern: "/pmg/", boardName: "biz")
        favorite.lastThumbnailUrlString = "https://example.com/old.jpg"
        await model.findMatches(for: favorite)
        guard case .error = model.state else { return XCTFail("Expected error") }
        await model.findMatches(for: favorite)
        XCTAssertEqual(model.state, .noMatches)
        XCTAssertNil(favorite.lastThumbnailUrlString)
    }

    private func catalog(_ threads: String) throws -> Catalog {
        try JSONDecoder().decode(Catalog.self, from: Data("[{\"page\":1,\"threads\":\(threads)}]".utf8))
    }

    func testBackupRestoreAddsMissingFavoritesAndKeepsExistingNames() throws {
        let container = try FavoritesStore.makeContainer(configuration: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        _ = try XCTUnwrap(RecurringFavoriteDraft(boardName: "biz", searchPattern: "pmg", displayName: "My Metals")).save(in: context)
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let backup = FavoritesBackup(threads: [.init(board: "biz", number: 100, title: "Saved thread", createdAt: date, savedAt: date)],
                                     generals: [.init(board: "biz", tag: "/pmg/", name: "Imported name", createdAt: date),
                                                .init(board: "g", tag: "/dpt/", name: "Daily Programming", createdAt: date)])
        let first = try FavoritesBackupStore.restore(backup, in: context)
        XCTAssertEqual(first.threads.count, 1)
        XCTAssertEqual(first.generals.count, 1)
        XCTAssertEqual(first.skipped, 1)
        let second = try FavoritesBackupStore.restore(backup, in: context)
        XCTAssertEqual(second.skipped, 3)
        let saved = try FavoritesBackupStore.export(from: context)
        XCTAssertEqual(saved.threads.count, 1)
        XCTAssertEqual(saved.threads.first?.savedAt, date)
        XCTAssertEqual(saved.generals.count, 2)
        XCTAssertEqual(saved.generals.first { $0.board == "biz" }?.name, "My Metals")
    }

    func testInvalidBackupDoesNotPartiallyInsertFavorites() throws {
        let container = try FavoritesStore.makeContainer(configuration: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let date = Date()
        let backup = FavoritesBackup(threads: [.init(board: "biz", number: 100, title: "Valid", createdAt: date, savedAt: date),
                                              .init(board: "biz", number: -1, title: "Invalid", createdAt: date, savedAt: date)], generals: [])
        XCTAssertThrowsError(try FavoritesBackupStore.restore(backup, in: context))
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<FavoriteThread>()), 0)
    }
}
