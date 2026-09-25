import XCTest
@testable import swiftchan

@MainActor
final class ReadingProgressTests: XCTestCase {
    func testProgressPersistsAcrossStoreInstancesAndIsScopedToBoardAndThread() throws {
        let name = "ReadingProgressTests.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let store = ThreadReadingStore(defaults: defaults)
        store.record(board: "BIZ", threadID: 100, postID: 105, highestReadID: 107)
        store.flush()
        let reloaded = ThreadReadingStore(defaults: defaults)
        XCTAssertEqual(reloaded.progress(board: "biz", threadID: 100)?.postID, 105)
        XCTAssertEqual(reloaded.progress(board: "biz", threadID: 100)?.highestReadID, 107)
        XCTAssertNil(reloaded.progress(board: "g", threadID: 100))
        XCTAssertNil(reloaded.progress(board: "biz", threadID: 101))
        reloaded.clear()
        XCTAssertNil(ThreadReadingStore(defaults: defaults).progress(board: "biz", threadID: 100))
    }

    func testReadingBackwardsMovesPositionWithoutLosingReadProgressAndEvictsOldest() {
        let store = ThreadReadingStore(defaults: nil, limit: 2)
        store.record(board: "biz", threadID: 1, postID: 10, highestReadID: 12, now: Date(timeIntervalSince1970: 1))
        store.record(board: "biz", threadID: 1, postID: 2, highestReadID: 3, now: Date(timeIntervalSince1970: 2))
        XCTAssertEqual(store.progress(board: "biz", threadID: 1)?.postID, 2)
        XCTAssertEqual(store.progress(board: "biz", threadID: 1)?.highestReadID, 12)
        store.record(board: "biz", threadID: 2, postID: 20, highestReadID: 20, now: Date(timeIntervalSince1970: 3))
        store.record(board: "biz", threadID: 3, postID: 30, highestReadID: 30, now: Date(timeIntervalSince1970: 4))
        XCTAssertNil(store.progress(board: "biz", threadID: 1))
        XCTAssertNotNil(store.progress(board: "biz", threadID: 2))
    }

    func testRestorationIgnoresInitialTopOfThreadVisibilityAndCountsActualReplies() {
        var reading = ThreadReadingSession()
        let posts = [100, 102, 105, 108, 110]
        XCTAssertEqual(reading.start(postIDs: posts, saved: saved(105), linkedPostID: nil), 105)
        reading.observe(visiblePostIDs: [100, 102])
        XCTAssertNil(reading.postID)
        XCTAssertEqual(reading.unreadPostIDs(in: posts), [108, 110])
        reading.observe(visiblePostIDs: [105, 108])
        XCTAssertEqual(reading.postID, 105)
        XCTAssertEqual(reading.unreadPostIDs(in: posts), [110])
        XCTAssertEqual(reading.firstNewPostID(in: posts), 108)
        reading.observe(visiblePostIDs: [102])
        XCTAssertEqual(reading.highestReadID, 108)
    }

    func testDeletedOrHiddenSavedPostFallsForwardAndFallsBackAtEnd() {
        var reading = ThreadReadingSession()
        XCTAssertEqual(reading.start(postIDs: [100, 108, 110], saved: saved(105), linkedPostID: nil), 108)
        var atEnd = ThreadReadingSession()
        XCTAssertEqual(atEnd.start(postIDs: [100, 102], saved: saved(105), linkedPostID: nil), 102)
    }

    func testExplicitPostLinkOverridesSavedPositionAndRefreshNeverRestoresAgain() {
        var reading = ThreadReadingSession()
        XCTAssertEqual(reading.start(postIDs: [100, 105, 110], saved: saved(105), linkedPostID: 110), 110)
        reading.observe(visiblePostIDs: [110])
        XCTAssertNil(reading.start(postIDs: [100, 105, 110, 112], saved: saved(105), linkedPostID: 110))
        XCTAssertEqual(reading.unreadPostIDs(in: [100, 105, 110, 112]), [112])
    }

    func testFirstVisitHasNoUnreadUntilRefreshAndEmptyResponseDoesNotConsumeRestore() {
        var reading = ThreadReadingSession()
        XCTAssertNil(reading.start(postIDs: [], saved: nil, linkedPostID: nil))
        XCTAssertFalse(reading.started)
        XCTAssertNil(reading.start(postIDs: [100, 105], saved: nil, linkedPostID: nil))
        reading.observe(visiblePostIDs: [100])
        XCTAssertTrue(reading.unreadPostIDs(in: [100, 105]).isEmpty)
        XCTAssertEqual(reading.unreadPostIDs(in: [100, 105, 108]), [108])
    }

    func testGeneralSuggestionRecognizesTagAndPrefillsNameWithoutGuessingOrdinaryTitles() throws {
        let suggestion = try XCTUnwrap(GeneralSuggestion(title: "/PMG/ - Precious Metals General"))
        XCTAssertEqual(suggestion.tag, "/pmg/")
        XCTAssertEqual(suggestion.name, "Precious Metals General")
        XCTAssertEqual(GeneralSuggestion(title: "Precious Metals General /pmg/")?.name, "Precious Metals General")
        XCTAssertEqual(GeneralSuggestion(title: "/pmg/")?.name, "")
        XCTAssertNil(GeneralSuggestion(title: "Precious Metals General"))
        XCTAssertNil(GeneralSuggestion(title: "https://example.com/pmg/"))
        XCTAssertNil(GeneralSuggestion(title: "buy/sell/trade"))
    }

    private func saved(_ postID: Int) -> ThreadReadingProgress {
        ThreadReadingProgress(postID: postID, highestReadID: postID, updatedAt: Date())
    }
}
