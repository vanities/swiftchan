import XCTest
import FourChan
@testable import swiftchan

final class DeepLinkerTests: XCTestCase {
    func testBoardQueryUsesNamedParameter() throws {
        let url = try XCTUnwrap(URL(string: "swiftchan:/board?name=po&source=share"))
        XCTAssertEqual(Deeplinker.getType(url: url), .board(name: "po"))
    }

    func testReplyQueryUsesNamedParameter() throws {
        let url = try XCTUnwrap(URL(string: "swiftchan:/reply?source=thread&id=123&extra=456"))
        XCTAssertEqual(Deeplinker.getType(url: url), .post(id: "123"))
    }

    func testMalformedCustomLinksAreRejected() throws {
        for text in ["swiftchan:/board", "swiftchan:/board?name=", "swiftchan:/board?name=po/tg",
                     "swiftchan:/thread?board=po", "swiftchan:/thread?board=po&id=0",
                     "swiftchan:/thread?board=po&id=-1", "swiftchan:/thread?board=po&id=hello",
                     "swiftchan:/thread?board=po&id=9999999999999999999999999",
                     "swiftchan:/thread?board=po&id=1&id=2", "swiftchan:/reply?id=abc"] {
            XCTAssertNil(Deeplinker.getType(url: try XCTUnwrap(URL(string: text))), text)
        }
    }

    func testWebsiteBoardAndCatalogLinks() throws {
        for text in ["https://boards.4chan.org/po/", "https://boards.4channel.org/po/catalog", "http://boards.4chan.org/po/2"] {
            XCTAssertEqual(Deeplinker.getType(url: try XCTUnwrap(URL(string: text))), .board(name: "po"), text)
        }
    }

    func testWebsiteThreadLinks() throws {
        for text in ["https://boards.4chan.org/po/thread/123", "https://boards.4channel.org/po/thread/123/paper-crafts?source=share"] {
            XCTAssertEqual(Deeplinker.getType(url: try XCTUnwrap(URL(string: text))), .thread(board: "po", id: "123"), text)
        }
    }

    func testUnrelatedSitesAndMalformedWebsiteLinksAreRejected() throws {
        for text in ["https://example.com/po/thread/123", "https://boards.4chan.org.example.com/po/",
                     "https://boards.4chan.org@evil.example/po/", "ftp://boards.4chan.org/po/",
                     "https://boards.4chan.org/po/thread/0", "https://boards.4chan.org/po/thread/nope",
                     "https://boards.4chan.org/po/not-a-page"] {
            XCTAssertNil(Deeplinker.getType(url: try XCTUnwrap(URL(string: text))), text)
        }
    }

    @MainActor
    func testQuotesOnlyResolveExactLoadedPosts() async throws {
        let response = try JSONDecoder().decode(ChanThread.self, from: Data(#"{"posts":[{"no":123},{"no":456}]}"#.utf8))
        let model = ThreadViewModel(boardName: "po", id: 123, fetchThread: { _, _, _ in response })
        await model.getPosts()
        XCTAssertEqual(model.getPostIndexFromId("456"), 1)
        XCTAssertNil(model.getPostIndexFromId("1234"))
        XCTAssertNil(model.getPostIndexFromId("999"))
        XCTAssertNil(model.getPostIndexFromId(""))
    }
}

extension DeepLinkerTests {
    func testPastedLinkTrimsWhitespaceAndAcceptsMissingScheme() {
        XCTAssertEqual(Deeplinker.parse("  boards.4chan.org/biz/\n"), .board(name: "biz"))
        XCTAssertNil(Deeplinker.parse(""))
    }

    func testThreadPostAnchorsArePreserved() {
        XCTAssertEqual(Deeplinker.parse("https://boards.4chan.org/po/thread/123/title#p456"), .thread(board: "po", id: "123", postID: 456))
        XCTAssertNil(Deeplinker.parse("https://boards.4chan.org/po/thread/123#pnope"))
    }

    @MainActor
    func testIncomingLinksSelectBoardsAndPreservePendingDestination() throws {
        let state = AppState()
        state.selectedTab = .favorites
        XCTAssertTrue(state.openLink(try XCTUnwrap(URL(string: "https://boards.4chan.org/biz/thread/123#p456"))))
        XCTAssertEqual(state.selectedTab, .boards)
        XCTAssertEqual(state.pendingLink, .thread(board: "biz", id: "123", postID: 456))
        XCTAssertFalse(state.openLink(try XCTUnwrap(URL(string: "https://example.com"))))
        XCTAssertFalse(state.openLink(.post(id: "456")))
    }
}

extension DeepLinkerTests {
    func testQuoteDestinationUsesHrefInsteadOfDecoratedLabel() {
        let comment = CommentParser(comment: ##"<a href="#p456" class="quotelink">&gt;&gt;456 (OP)</a>"##).getComment()
        XCTAssertEqual(comment.runs.compactMap { $0.link }.first, URL.inThreadReply(id: "456"))
    }

    func testCommentWebsiteLinkPreservesPostFragmentAndExistingEscapes() {
        let url = "https://boards.4chan.org/po/thread/123/paper%20craft#p456"
        let comment = CommentParser(comment: "<a href=\"\(url)\">thread</a>").getComment()
        XCTAssertEqual(comment.runs.compactMap { $0.link }.first?.absoluteString, url)
    }
}
