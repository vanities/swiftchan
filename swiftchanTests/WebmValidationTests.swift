import XCTest
@testable import swiftchan

final class WebmValidationTests: XCTestCase {
    func testValidWebmHeader() throws {
        try assertValidation([0x1A, 0x45, 0xDF, 0xA3], expected: true)
    }

    func testValidMP4Header() throws {
        try assertValidation([0, 0, 0, 24, 0x66, 0x74, 0x79, 0x70], expected: true)
    }

    func testRejectsHTMLErrorResponse() throws {
        try assertValidation(Array("<html>404 Not Found</html>".utf8), expected: false)
    }

    func testRejectsEmptyAndTruncatedHeaders() throws {
        try assertValidation([], expected: false)
        try assertValidation([0x1A, 0x45, 0xDF], expected: false)
        try assertValidation([0, 0, 0, 24, 0x66, 0x74, 0x79], expected: false)
    }

    func testRejectsMissingFile() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        XCTAssertFalse(CacheManager.shared.isValidVideoFile(file: url))
    }

    func testCorruptVideoIsNotACacheHit() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("webm")
        defer { try? FileManager.default.removeItem(at: url) }
        try Data("<html>Not Found</html>".utf8).write(to: url)
        XCTAssertFalse(CacheManager.shared.cacheHit(file: url))
    }

    func testInvalidDownloadCannotReplaceValidCachedVideo() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let source = directory.appendingPathComponent("download")
        let destination = directory.appendingPathComponent("cached.webm")
        let validHeader = Data([0x1A, 0x45, 0xDF, 0xA3])
        try Data("<html>Not Found</html>".utf8).write(to: source)
        try validHeader.write(to: destination)

        XCTAssertNil(CacheManager.shared.cache(source, destination))
        XCTAssertEqual(try Data(contentsOf: destination), validHeader)
    }

    func testCachePathHandlesExtensionlessAndDottedFilenames() {
        XCTAssertEqual(CacheManager.shared.directoryFor(stringUrl: "https://example.com/video").lastPathComponent, "video-cached")
        XCTAssertEqual(CacheManager.shared.directoryFor(stringUrl: "https://example.com/my.video.mp4").lastPathComponent, "my.video-cached.mp4")
    }

    func testInvalidDownloadURLCompletes() {
        let completed = expectation(description: "invalid URL completes")
        completed.assertForOverFulfill = true
        CacheManager.shared.getFileWith(stringUrl: "relative/path") { url in
            XCTAssertNil(url)
            completed.fulfill()
        }
        wait(for: [completed], timeout: 1)
    }

    func testNetworkFailureCompletes() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FailingDownloadProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let cache = CacheManager(session: session)
        let completed = expectation(description: "network failure completes")
        completed.assertForOverFulfill = true

        cache.getFileWith(stringUrl: "https://example.com/\(UUID().uuidString).webm") { url in
            XCTAssertNil(url)
            completed.fulfill()
        }

        wait(for: [completed], timeout: 2)
    }

    func testLocalCachedFileCanBeReadWithoutDownloadingAgain() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("webm")
        defer { try? FileManager.default.removeItem(at: url) }
        try Data([0x1A, 0x45, 0xDF, 0xA3]).write(to: url)
        let completed = expectation(description: "local file completes")
        CacheManager.shared.getFileWith(stringUrl: url.absoluteString) { result in
            XCTAssertEqual(result, url)
            completed.fulfill()
        }
        wait(for: [completed], timeout: 1)
    }

    private func assertValidation(_ bytes: [UInt8], expected: Bool, file: StaticString = #filePath, line: UInt = #line) throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        try Data(bytes).write(to: url)
        XCTAssertEqual(CacheManager.shared.isValidVideoFile(file: url), expected, file: file, line: line)
    }
}

private class FailingDownloadProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
    }
    override func stopLoading() {}
}
