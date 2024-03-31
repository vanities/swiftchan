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

    @MainActor func testAppLoadsBoards() throws {
        XCTAssertGreaterThan(app.staticTexts.count, 10)
        app.assertBoardButton("3")
        app.assertBoardButton("a")
        app.assertBoardButton("adv")
        app.assertBoardButton("an")
        app.assertBoardButton("biz")
        app.assertBoardButton("c")
        app.assertBoardButton("cgl")
        app.assertBoardButton("ck")
        app.assertBoardButton("cm")
        // app.assertBoardButton("co")
        // app.assertBoardButton("d")
        // app.assertBoardButton("diy")
    }

    @MainActor func testAppLoadsOPPosts() throws {
        app.goToBoard("a")
        app.assertOpButton(0)
        app.assertOpButton(1)
        app.assertOpButton(2)
        app.assertOpButton(3)
        // app.assertOPThread(4)
        // app.assertOPThread(5)
    }

    // TODO: Fix tests below in CI
    // Failed to synthesize event: Failed to scroll to visible (by AX action)

    @MainActor func x_testAppLoadsPosts() throws {
        app.goToBoard("a")
        app.goToOPThread(0)

        app.assertPost(0)
        // app.assertPost(1)
    }

    @MainActor func x_testImageDownloaderSavesFiles() throws {
        app.goToBoard("a")
        app.goToOPThread(0)
        app.assertPost(0)
        app.tapThumbnailMedia(0)
        app.longPressGalleryMedia(0)
        app.tapSaveToPhotosButton()
        // app.assertSuccessToastImage()
    }

    @MainActor func x_testImageCopierCopiesUrlToPasteboard() throws {
        app.goToBoard("a")
        app.goToOPThread(0)
        app.assertPost(0)
        app.tapThumbnailMedia(0)
        app.longPressGalleryMedia(0)
        app.tapCopyToPasteboardButton()
        XCTAssert(UIPasteboard.general.hasURLs)
    }
}
