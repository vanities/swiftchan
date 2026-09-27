import XCTest
import FourChan
import Observation
@testable import swiftchan

@MainActor
final class ThreadViewModelTests: XCTestCase {
    func testNativeArchivedThreadDisablesLiveRefreshState() async throws {
        let response = try thread(#"[{"no":100,"archived":1},{"no":105}]"#)
        let model = ThreadViewModel(boardName: "biz", id: 100, fetchThread: { _, _, _ in response })
        await model.getPosts()
        XCTAssertTrue(model.isArchived)
        XCTAssertFalse(model.isFromArchive)
        XCTAssertNil(model.archiveUrl)
    }

    func testPersistentFiltersScopeAndHidePriority() throws {
        let name = "PostFiltersTests.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let store = PostFilterStore(defaults: defaults)
        let post = try XCTUnwrap(thread(#"[{"no":100,"id":"abc123","name":"Alice","trip":"!trip"}]"#).posts.first)
        store.add(PostFilterRule(board: "/BIZ/", field: .keyword, pattern: "Gold", action: .highlight))
        XCTAssertEqual(store.effect(board: "biz", post: post, text: "gold coins"), .highlight)
        XCTAssertNil(store.effect(board: "g", post: post, text: "gold coins"))
        let hide = PostFilterRule(board: nil, field: .posterID, pattern: "ABC123", action: .hide)
        store.add(hide)
        XCTAssertEqual(store.effect(board: "biz", post: post, text: "gold coins"), .hide)
        let reloaded = PostFilterStore(defaults: defaults)
        XCTAssertEqual(reloaded.rules.count, 2)
        reloaded.remove(hide)
        XCTAssertEqual(PostFilterStore(defaults: defaults).rules.count, 1)
        XCTAssertFalse(PostFilterRule(board: nil, field: .posterID, pattern: "abc", action: .hide)
            .matches(board: "biz", text: "", posterID: "abc123", name: nil, tripcode: nil))
        XCTAssertTrue(PostFilterRule(board: nil, field: .tripcode, pattern: "!trip", action: .hide)
            .matches(board: "biz", text: "", posterID: nil, name: nil, tripcode: "!TRIP"))
    }

    func testWatcherConditionalRefreshUnreadAndFailurePreserveLastResult() async {
        let target = WatchTarget(board: "biz", threadID: 100)
        var calls = 0
        let watcher = ThreadWatcher(interval: 0) { _, modified in
            calls += 1
            if calls == 1 {
                return .changed(WatchedThread(replyIDs: [103, 105, 110], archived: true, missing: false, lastModified: "date"))
            }
            XCTAssertEqual(modified, "date")
            if calls == 2 { return .unchanged }
            throw URLError(.notConnectedToInternet)
        }
        await watcher.refresh([target])
        XCTAssertEqual(watcher.results[target.id]?.unread(after: 105), 1)
        XCTAssertNil(watcher.results[target.id]?.unread(after: nil))
        await watcher.refresh([target])
        XCTAssertEqual(watcher.results[target.id]?.replyIDs, [103, 105, 110])
        await watcher.refresh([target])
        XCTAssertNotNil(watcher.errors[target.id])
        XCTAssertEqual(watcher.results[target.id]?.replyIDs.count, 3)
    }

    func testWatcherCooldownDoesNotRepeatRequests() async {
        var calls = 0
        let watcher = ThreadWatcher(interval: 30) { _, _ in
            calls += 1
            return .changed(WatchedThread(replyIDs: [], archived: false, missing: true))
        }
        let targets = [WatchTarget(board: "biz", threadID: 100)]
        await watcher.refresh(targets)
        await watcher.refresh(targets)
        XCTAssertEqual(calls, 1)
        XCTAssertTrue(watcher.results["biz/100"]?.missing == true)
    }

    func testDiscardingTemporaryRefresherDoesNotInvalidatePresentingView() {
        let invalidation = expectation(description: "Temporary timer does not invalidate view construction")
        invalidation.isInverted = true
        var refresher: ThreadAutoRefresher? = withObservationTracking {
            ThreadAutoRefresher()
        } onChange: {
            invalidation.fulfill()
        }
        XCTAssertNotNil(refresher)
        XCTAssertFalse(refresher?.isActive ?? true)
        refresher = nil
        wait(for: [invalidation], timeout: 0.05)
    }

    func testSharedPostLinkPreservesBoardThreadAndExactReply() {
        let model = ThreadViewModel(boardName: "biz", id: 100)
        XCTAssertEqual(model.postURL(105).absoluteString, "https://boards.4chan.org/biz/thread/100#p105")
        XCTAssertEqual(Deeplinker.getType(url: model.postURL(105)), .thread(board: "biz", id: "100", postID: 105))
        XCTAssertEqual(model.postURL(100).fragment, "p100")
        XCTAssertNil(model.url.fragment)
    }

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
