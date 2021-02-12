//
//  swiftchanTests.swift
//  swiftchanTests
//
//  Created by vanities on 10/30/20.
//

import XCTest
@testable import swiftchan

class SwiftchanTests: XCTestCase {
    let postParser = PostTextParser()
    let parser = CommentParser(comment: "https://www.youtube.com/watch?v=kg4<wbr>YFS6b0ek")

    let allText = "<a href=\"/fit/thread/59717832#p59725765\" class=\"quotelink\">&gt;&gt;59725765</a><br>Would https://www.soundcloud.com<br><span class=\"quote\">&gt;24 hour fast during family superbowl party</span><br>"
    let hyperlinkText = "<a href=\"/fit/thread/59717832#p59725765\" class=\"quotelink\">&gt;&gt;59725765</a> aa https://mpv.io/installation/ b"

    func testHyperLinkParse() throws {
        self.postParser.parse(text: self.hyperlinkText) { element in
            print(element)
            switch element {
            case .hyperLink(let url):
                break
                // XCTAssert(url == URL(string: hyperlinkText)!)
            default:
                break
                // XCTAssert(false)
            }
        }
    }

    func testParserAttributesString() throws {
        let string = parser.parseComment(self.allText)
    }
}
