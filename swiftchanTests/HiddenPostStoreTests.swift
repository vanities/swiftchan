import XCTest
@testable import swiftchan

@MainActor
final class HiddenPostStoreTests: XCTestCase {
    func testHideRestoreAndReloadAreBoardScopedAndPreserveThreadMetadata() throws {
        let (defaults, name) = try isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: name) }
        let store = HiddenPostStore(defaults: defaults)
        let thread = try XCTUnwrap(store.hide(board: "/BIZ/", postID: 100, threadID: 100, title: " /pmg/ "))
        XCTAssertTrue(thread.isThread)
        XCTAssertEqual(thread.title, "/pmg/")
        XCTAssertTrue(store.isHidden(board: "biz", postID: 100))
        XCTAssertFalse(store.isHidden(board: "g", postID: 100))
        _ = store.hide(board: "g", postID: 100, threadID: 90)
        XCTAssertEqual(HiddenPostStore(defaults: defaults).items.count, 2)
        store.restore(thread)
        let reloaded = HiddenPostStore(defaults: defaults)
        XCTAssertFalse(reloaded.isHidden(board: "biz", postID: 100))
        XCTAssertTrue(reloaded.isHidden(board: "g", postID: 100))
        XCTAssertFalse(try XCTUnwrap(reloaded.items.first).isThread)
    }

    func testLegacyFlagsRemainHiddenUntilRestoredAndDoNotReappearAfterRelaunch() throws {
        let (defaults, name) = try isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set(true, forKey: "hiddenPosts board=BIZ postId=100")
        defaults.set(true, forKey: "hiddenPosts board=g postId=200")
        defaults.set(false, forKey: "hiddenPosts board=biz postId=300")
        defaults.set(true, forKey: "hiddenPosts board=biz postId=bad")
        defaults.set(true, forKey: "unrelatedPreference")
        let store = HiddenPostStore(defaults: defaults)
        XCTAssertEqual(store.items.count, 2)
        XCTAssertTrue(store.isHidden(board: "biz", postID: 100))
        store.restore(try XCTUnwrap(store.items.first { $0.postID == 100 }))
        XCTAssertFalse(HiddenPostStore(defaults: defaults).isHidden(board: "biz", postID: 100))
        store.restoreAll()
        XCTAssertTrue(HiddenPostStore(defaults: defaults).items.isEmpty)
        XCTAssertTrue(defaults.bool(forKey: "unrelatedPreference"))
        XCTAssertTrue(defaults.bool(forKey: "hiddenPosts board=biz postId=bad"))
    }

    func testRepeatedHideIsIdempotentAndNewestItemsComeFirst() throws {
        let store = HiddenPostStore(defaults: nil)
        let first = try XCTUnwrap(store.hide(board: "biz", postID: 1, now: Date(timeIntervalSince1970: 1)))
        _ = store.hide(board: "biz", postID: 2, now: Date(timeIntervalSince1970: 2))
        XCTAssertEqual(store.hide(board: "biz", postID: 1), first)
        XCTAssertEqual(store.items.map(\.postID), [2, 1])
        XCTAssertNil(store.hide(board: "bad/board", postID: 1))
        XCTAssertNil(store.hide(board: "biz", postID: 0))
        store.restore(first)
        XCTAssertEqual(store.items.map(\.postID), [2])
    }

    func testCorruptNewStoreStillLoadsLegacyFlags() throws {
        let (defaults, name) = try isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set(Data("broken".utf8), forKey: "hiddenPosts.v1")
        defaults.set(true, forKey: "hiddenPosts board=biz postId=100")
        XCTAssertTrue(HiddenPostStore(defaults: defaults).isHidden(board: "biz", postID: 100))
    }

    private func isolatedDefaults() throws -> (UserDefaults, String) {
        let name = "HiddenPostStoreTests.\(UUID())"
        return (try XCTUnwrap(UserDefaults(suiteName: name)), name)
    }
}
