import XCTest
import SwiftData
import FourChan
@testable import swiftchan

@MainActor
final class RecurringFavoriteTests: XCTestCase {
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
}
