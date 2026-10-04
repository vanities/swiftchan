import XCTest
@testable import swiftchan

final class ReverseImageSearchTests: XCTestCase {
    func testEachProviderReceivesTheOriginalImageURL() throws {
        let original = try XCTUnwrap(URL(string: "https://i.4cdn.org/g/123.png"))
        let thumbnail = try XCTUnwrap(URL(string: "https://i.4cdn.org/g/123s.jpg"))
        let media = Media(index: 0, url: original, thumbnailUrl: thumbnail)
        let hosts = ["lens.google.com", "yandex.com", "tineye.com", "saucenao.com", "iqdb.org", "trace.moe"]
        for (provider, host) in zip(ReverseImageSearchProvider.allCases, hosts) {
            let url = try XCTUnwrap(provider.searchURL(for: media))
            XCTAssertEqual(url.scheme, "https")
            XCTAssertEqual(url.host, host)
            XCTAssertEqual(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "url" }?.value,
                           original.absoluteString)
        }
    }

    func testSearchQueryPreservesEscapesAndFormSensitiveCharacters() throws {
        let original = try XCTUnwrap(URL(string: "https://images.example/image%20name.PNG?token=a+b&escaped=%2B%26#fragment"))
        let media = Media(index: 0, url: original, thumbnailUrl: original)
        for provider in ReverseImageSearchProvider.allCases {
            let url = try XCTUnwrap(provider.searchURL(for: media))
            let query = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false)?.percentEncodedQuery)
            XCTAssertFalse(query.contains("+"), "Providers interpret raw + as a space")
            XCTAssertEqual(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "url" }?.value,
                           original.absoluteString)
        }
    }

    func testVideoSearchesUseThumbnailsInsteadOfVideoFiles() throws {
        let thumbnail = try XCTUnwrap(URL(string: "https://i.4cdn.org/g/123s.jpg"))
        for ext in ["webm", "mp4"] {
            let media = Media(index: 0, url: try XCTUnwrap(URL(string: "https://i.4cdn.org/g/123.\(ext)")), thumbnailUrl: thumbnail)
            XCTAssertTrue(ReverseImageSearchProvider.usesThumbnail(for: media))
            XCTAssertEqual(ReverseImageSearchProvider.sourceURL(for: media), thumbnail)
            for provider in ReverseImageSearchProvider.allCases {
                let url = try XCTUnwrap(provider.searchURL(for: media))
                XCTAssertEqual(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "url" }?.value,
                               thumbnail.absoluteString)
            }
        }
    }

    func testGIFSearchesUseTheOriginalAnimation() throws {
        let gif = try XCTUnwrap(URL(string: "https://i.4cdn.org/g/123.gif"))
        let media = Media(index: 0, url: gif, thumbnailUrl: try XCTUnwrap(URL(string: "https://i.4cdn.org/g/123s.jpg")))
        XCTAssertEqual(ReverseImageSearchProvider.sourceURL(for: media), gif)
        XCTAssertFalse(ReverseImageSearchProvider.usesThumbnail(for: media))
    }

    func testLocalUnsupportedAndCredentialedSourcesDoNotProduceSearchLinks() throws {
        for text in ["file:///tmp/photo.png", "https://example.com/document.pdf", "https://user:password@example.com/photo.png"] {
            let url = try XCTUnwrap(URL(string: text))
            let media = Media(index: 0, url: url, thumbnailUrl: url)
            for provider in ReverseImageSearchProvider.allCases { XCTAssertNil(provider.searchURL(for: media)) }
        }
    }

    func testYandexIncludesImageSearchMode() throws {
        let url = try XCTUnwrap(URL(string: "https://i.4cdn.org/g/123.jpg"))
        let search = try XCTUnwrap(ReverseImageSearchProvider.yandex.searchURL(for: Media(index: 0, url: url, thumbnailUrl: url)))
        XCTAssertEqual(URLComponents(url: search, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "rpt" }?.value, "imageview")
    }
}
