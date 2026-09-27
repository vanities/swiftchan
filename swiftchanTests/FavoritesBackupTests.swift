import XCTest
@testable import swiftchan

final class FavoritesBackupTests: XCTestCase {
    private let date = Date(timeIntervalSince1970: 1_700_000_000)

    func testRoundTripPreservesLinksNamesAndDates() throws {
        let backup = example()
        XCTAssertEqual(try FavoritesBackup.decode(backup.encoded()), backup)
    }

    func testImportNormalizesBeforeDeduplicatingAndKeepsExistingFavorites() throws {
        var backup = example()
        backup.threads.append(.init(board: "/BIZ/", number: 100, title: "Duplicate", createdAt: date, savedAt: date))
        backup.threads.append(.init(board: "g", number: 100, title: "Different board", createdAt: date, savedAt: date))
        backup.generals.append(.init(board: "/BIZ/", tag: "PMG", name: "Duplicate", createdAt: date))
        let plan = try backup.importPlan(threadKeys: ["biz/100"], generalKeys: ["biz//pmg/"])
        XCTAssertEqual(plan.threads.map(\.key), ["g/100"])
        XCTAssertTrue(plan.generals.isEmpty)
        XCTAssertEqual(plan.skipped, 4)
        let emptyPlan = try backup.importPlan(threadKeys: [], generalKeys: [])
        XCTAssertEqual(emptyPlan.threads.count, 2)
        XCTAssertEqual(emptyPlan.generals.count, 1)
        XCTAssertEqual(emptyPlan.generals.first?.name, "Precious Metals General")
    }

    func testInvalidRecordRejectsTheEntireBackup() throws {
        var backup = example()
        backup.threads.append(.init(board: "bad/board", number: 200, title: "Invalid", createdAt: date, savedAt: date))
        XCTAssertThrowsError(try backup.importPlan(threadKeys: [], generalKeys: []))
        backup = example()
        backup.generals[0].tag = "///"
        XCTAssertThrowsError(try backup.encoded())
        backup = example()
        backup.generals[0].tag = "pmg\rbroken"
        XCTAssertThrowsError(try backup.encoded())
    }

    func testRejectsUnknownFormatsVersionsAndOversizedFiles() throws {
        let data = try example().encoded()
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object["version"] = 3
        XCTAssertThrowsError(try FavoritesBackup.decode(JSONSerialization.data(withJSONObject: object)))
        object["version"] = 1
        object["format"] = "another.app"
        XCTAssertThrowsError(try FavoritesBackup.decode(JSONSerialization.data(withJSONObject: object)))
        XCTAssertThrowsError(try FavoritesBackup.decode(Data(repeating: 0, count: FavoritesBackup.maximumBytes + 1)))
        XCTAssertThrowsError(try FavoritesBackup.decode(Data("not JSON".utf8)))
    }

    func testEmptyBackupIsAValidNoOp() throws {
        let backup = try FavoritesBackup.decode(FavoritesBackup(threads: [], generals: []).encoded())
        let plan = try backup.importPlan(threadKeys: [], generalKeys: [])
        XCTAssertTrue(plan.threads.isEmpty)
        XCTAssertTrue(plan.generals.isEmpty)
        XCTAssertEqual(plan.skipped, 0)
    }

    private func example() -> FavoritesBackup {
        FavoritesBackup(threads: [.init(board: "biz", number: 100, title: "/pmg/", createdAt: date, savedAt: date)],
                        generals: [.init(board: "biz", tag: "/pmg/", name: "Precious Metals General", createdAt: date)], exportedAt: date)
    }
}
