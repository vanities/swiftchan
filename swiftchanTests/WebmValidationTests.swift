import XCTest
@testable import swiftchan

final class WebmValidationTests: XCTestCase {
    func testValidWebmHeader() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("sample.webm")
        let bytes: [UInt8] = [0x1A, 0x45, 0xDF, 0xA3]
        try Data(bytes).write(to: url)
        XCTAssertTrue(CacheManager.shared.isValidWebm(file: url))
    }
}
