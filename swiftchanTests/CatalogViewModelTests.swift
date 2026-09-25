import XCTest
import FourChan
@testable import swiftchan

@MainActor
final class CatalogViewModelTests: XCTestCase {
    func testRefreshReplacesCachedResultsWhenThreadCountIsUnchanged() async throws {
        let old = try catalog(#"[{"no":1,"sub":"old thread"}]"#)
        let fresh = try catalog(#"[{"no":2,"sub":"new thread"}]"#)
        var responses = [old, fresh]
        let model = CatalogViewModel(boardName: UUID().uuidString) { _, _ in responses.removeFirst() }

        await model.load()
        XCTAssertEqual(model.getFilteredPosts(searchText: "").map(\.id), [1])
        await model.load()

        XCTAssertEqual(model.getFilteredPosts(searchText: "").map(\.id), [2])
    }

    func testRefreshUpdatesActiveSearchAndClampsSelection() async throws {
        var responses = [
            try catalog(#"[{"no":1,"sub":"match"},{"no":2,"sub":"match"}]"#),
            try catalog(#"[{"no":3,"sub":"match"},{"no":4,"sub":"other"}]"#)
        ]
        let model = CatalogViewModel(boardName: UUID().uuidString) { _, _ in responses.removeFirst() }
        await model.load()
        model.searchText = "match"
        model.updateSearchResults()
        model.jumpToNextSearchResult()
        XCTAssertEqual(model.currentSearchResultIndex, 1)

        await model.load()

        XCTAssertEqual(model.searchResultIndices.count, 1)
        XCTAssertEqual(model.currentSearchResultIndex, 0)
        let index = try XCTUnwrap(model.getCurrentSearchResultPostIndex())
        XCTAssertEqual(model.posts[index].id, 3)
    }

    func testSearchNavigationUsesCurrentSortedPositions() async throws {
        let data = try catalog(#"[{"no":1,"sub":"match","replies":1},{"no":2,"sub":"other","replies":10},{"no":3,"sub":"match","replies":5}]"#)
        let model = CatalogViewModel(boardName: UUID().uuidString) { _, _ in data }
        await model.load()
        model.searchText = "match"
        model.updateSearchResults()

        model.handleSorting(value: .descending, attributeKey: "replies")

        XCTAssertEqual(model.posts.map(\.id), [2, 3, 1])
        var index = try XCTUnwrap(model.getCurrentSearchResultPostIndex())
        XCTAssertEqual(model.posts[index].id, 3)
        model.jumpToNextSearchResult()
        index = try XCTUnwrap(model.getCurrentSearchResultPostIndex())
        XCTAssertEqual(model.posts[index].id, 1)
    }

    func testFailedRefreshKeepsPreviouslyLoadedCatalog() async throws {
        let data = try catalog(#"[{"no":1,"sub":"cached thread"}]"#)
        var calls = 0
        let model = CatalogViewModel(boardName: UUID().uuidString) { _, _ in
            calls += 1
            if calls > 1 { throw URLError(.notConnectedToInternet) }
            return data
        }
        await model.load()
        await model.load()

        XCTAssertEqual(model.state, .loaded)
        XCTAssertEqual(model.posts.map(\.id), [1])
        XCTAssertNotNil(model.refreshError)
    }

    func testInitialFailureCanBeRetried() async throws {
        let data = try catalog(#"[{"no":1,"sub":"recovered"}]"#)
        var calls = 0
        let model = CatalogViewModel(boardName: UUID().uuidString) { _, _ in
            calls += 1
            if calls == 1 { throw URLError(.notConnectedToInternet) }
            return data
        }
        await model.load()
        XCTAssertEqual(model.state, .error)

        await model.load()

        XCTAssertEqual(model.state, .loaded)
        XCTAssertNil(model.refreshError)
        XCTAssertEqual(model.posts.map(\.id), [1])
    }

    func testEmptyRefreshClearsSearchResults() async throws {
        var responses = [try catalog(#"[{"no":1,"sub":"match"}]"#), try catalog("[]")]
        let model = CatalogViewModel(boardName: UUID().uuidString) { _, _ in responses.removeFirst() }
        model.searchText = "match"
        await model.load()
        XCTAssertEqual(model.searchResultIndices.count, 1)

        await model.load()

        XCTAssertTrue(model.getFilteredPosts(searchText: "match").isEmpty)
        XCTAssertTrue(model.searchResultIndices.isEmpty)
        XCTAssertNil(model.getCurrentSearchResultPostIndex())
    }

    private func catalog(_ threads: String) throws -> Catalog {
        try JSONDecoder().decode(Catalog.self, from: Data("[{\"page\":1,\"threads\":\(threads)}]".utf8))
    }
}
