import XCTest
import FourChan
@testable import swiftchan

@MainActor
final class ThreadViewModelTests: XCTestCase {
    func testRefreshFailurePreservesReadablePostsAndReportsError() async throws {
        let response = try thread(#"[{"no":1,"com":"Original post","tim":123,"ext":".jpg"}]"#)
        var calls = 0
        let model = ThreadViewModel(boardName: "po", id: 1, fetchThread: { _, _, _ in
            calls += 1
            if calls > 1 { throw URLError(.notConnectedToInternet) }
            return response
        })
        await model.getPosts()
        await model.getPosts()

        XCTAssertEqual(model.state, .loaded)
        XCTAssertEqual(model.posts.map(\.id), [1])
        XCTAssertEqual(model.postMediaMapping, [0: 0])
        XCTAssertEqual(String(model.comment(at: 0).characters), "Original post")
        XCTAssertNotNil(model.refreshError)
    }

    func testRefreshRecomputesActiveSearchForNewReplies() async throws {
        var responses = [
            try thread(#"[{"no":1,"com":"match"}]"#),
            try thread(#"[{"no":1,"com":"match"},{"no":2,"com":"another match"}]"#)
        ]
        let model = ThreadViewModel(boardName: "po", id: 1, fetchThread: { _, _, _ in responses.removeFirst() })
        await model.getPosts()
        model.searchText = "match"
        model.updateSearchResults()
        await model.getPosts()

        XCTAssertEqual(model.searchResultIndices, [0, 1])
        XCTAssertTrue(model.shouldShowPost(at: 1))
    }

    func testRefreshClampsSearchSelectionAfterPostRemoval() async throws {
        var responses = [
            try thread(#"[{"no":1,"com":"match"},{"no":2,"com":"match"}]"#),
            try thread(#"[{"no":1,"com":"match"}]"#)
        ]
        let model = ThreadViewModel(boardName: "po", id: 1, fetchThread: { _, _, _ in responses.removeFirst() })
        await model.getPosts()
        model.searchText = "match"
        model.updateSearchResults()
        model.jumpToNextSearchResult()
        await model.getPosts()

        XCTAssertEqual(model.currentSearchResultIndex, 0)
        XCTAssertEqual(model.getCurrentSearchResultPostIndex(), 0)
        XCTAssertEqual(model.searchResultIndices, [0])
    }

    func testFailedArchiveLoadDoesNotMarkLivePostsArchived() async throws {
        let response = try thread(#"[{"no":1,"com":"live post"}]"#)
        let model = ThreadViewModel(boardName: "tg", id: 1, fetchThread: { _, _, _ in response }, fetchArchive: { _, _ in
            throw FourplebsService.FourplebsError.antiBot
        })
        await model.getPosts()
        await model.loadFromArchive()

        XCTAssertFalse(model.isArchived)
        XCTAssertEqual(model.state, .loaded)
        XCTAssertEqual(model.posts.map(\.id), [1])
    }

    func testSuccessfulLiveLoadReplacesArchiveStateAndMedia() async throws {
        let archive = try JSONDecoder().decode(FourplebsThread.self, from: Data(#"{"op":{"num":"1","comment":"archived match","media":{"media_id":"123","media_filename":"one.jpg","media_link":"https://archive.example.com/one.jpg","thumb_link":"https://archive.example.com/thumb.jpg"}}}"#.utf8))
        let response = try thread(#"[{"no":1,"com":"live match"}]"#)
        let model = ThreadViewModel(boardName: "tg", id: 1, fetchThread: { _, _, _ in response }, fetchArchive: { _, _ in archive })
        model.searchText = "match"
        await model.loadFromArchive()
        XCTAssertTrue(model.isArchived)
        XCTAssertEqual(model.searchResultIndices, [0])
        XCTAssertEqual(model.media.first?.url.absoluteString, "https://archive.example.com/one.jpg")

        await model.getPosts()

        XCTAssertFalse(model.isArchived)
        XCTAssertTrue(model.media.isEmpty)
        XCTAssertTrue(model.postMediaMapping.isEmpty)
        XCTAssertEqual(String(model.comment(at: 0).characters), "live match")
    }

    func testDNSFailureIsNetworkErrorRatherThanMissingThread() async {
        let model = ThreadViewModel(boardName: "po", id: 1, fetchThread: { _, _, _ in throw URLError(.cannotFindHost) })
        await model.getPosts()
        XCTAssertEqual(model.state, .error)
        XCTAssertEqual(model.errorType, .network)
    }

    func testCancelledRefreshKeepsContentWithoutErrorMessage() async throws {
        let response = try thread(#"[{"no":1,"com":"post"}]"#)
        var calls = 0
        let model = ThreadViewModel(boardName: "po", id: 1, fetchThread: { _, _, _ in
            calls += 1
            if calls > 1 { throw CancellationError() }
            return response
        })
        await model.getPosts()
        await model.getPosts()
        XCTAssertEqual(model.state, .loaded)
        XCTAssertNil(model.refreshError)
    }

    func testOverlappingLoadDoesNotIssueAnotherRequest() async throws {
        let response = try thread(#"[{"no":1}]"#)
        let entered = expectation(description: "request started")
        var resume: CheckedContinuation<ChanThread, Error>?
        var calls = 0
        let model = ThreadViewModel(boardName: "po", id: 1, fetchThread: { _, _, _ in
            calls += 1
            return try await withCheckedThrowingContinuation { continuation in
                resume = continuation
                entered.fulfill()
            }
        })
        let loading = Task { await model.getPosts() }
        await fulfillment(of: [entered], timeout: 1)
        let overlapping = await model.getPosts()
        XCTAssertFalse(overlapping)
        XCTAssertEqual(calls, 1)
        resume?.resume(returning: response)
        let succeeded = await loading.value
        XCTAssertTrue(succeeded)
        XCTAssertEqual(model.state, .loaded)
    }

    func testSuccessfulRetryClearsRefreshError() async throws {
        let response = try thread(#"[{"no":1}]"#)
        var calls = 0
        let model = ThreadViewModel(boardName: "po", id: 1, fetchThread: { _, _, _ in
            calls += 1
            if calls == 2 { throw URLError(.notConnectedToInternet) }
            return response
        })
        await model.getPosts()
        await model.getPosts()
        XCTAssertNotNil(model.refreshError)
        await model.getPosts()
        XCTAssertNil(model.refreshError)
        XCTAssertEqual(model.state, .loaded)
    }

    func testCommentOutsideLoadedPostRangeIsEmpty() async throws {
        let response = try thread(#"[{"no":1,"com":"post"}]"#)
        let model = ThreadViewModel(boardName: "po", id: 1, fetchThread: { _, _, _ in response })
        await model.getPosts()
        XCTAssertEqual(model.comment(at: -1), AttributedString())
        XCTAssertEqual(model.comment(at: 1), AttributedString())
    }

    private func thread(_ posts: String) throws -> ChanThread {
        try JSONDecoder().decode(ChanThread.self, from: Data("{\"posts\":\(posts)}".utf8))
    }
}
