//
//  swiftchanUITests.swift
//  swiftchanUITests
//
//  Created by vanities on 10/30/20.
//

import XCTest
@testable import swiftchan

class SwiftchanUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        app = XCUIApplication()
        app.launchArguments = ["testing"]
        app.launch()

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        app.terminate()
    }

    func testAppLoadsBoards() throws {
        let boards = app.buttons[AccessibilityLabels.board]
        XCTAssertEqual(boards.staticTexts.count, 30)
    }

    func testAppLoadsOPPosts() throws {
        let firstBoard = app.buttons[AccessibilityLabels.board].firstMatch
        firstBoard.tap()

        let opPosts = app.buttons[AccessibilityLabels.opPost]
        opPosts.waitForExistence(timeout: 5)
        XCTAssertEqual(opPosts.staticTexts.count, 16)
    }

    func testAppLoadsPosts() throws {
        let firstBoard = app.buttons[AccessibilityLabels.board].firstMatch
        firstBoard.tap()

        let opPosts = app.buttons[AccessibilityLabels.opPost]
        if opPosts.waitForExistence(timeout: 5) {
            opPosts.firstMatch.tap()
        }

        let posts = app.staticTexts[AccessibilityLabels.postComment]
        posts.waitForExistence(timeout: 5)

        XCTAssert(posts.exists)
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
