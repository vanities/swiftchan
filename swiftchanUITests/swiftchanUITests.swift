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
        XCTAssertGreaterThan(app.buttons.count, 10)
        app.assertBoardButton("3")
        app.assertBoardButton("a")
        app.assertBoardButton("aco")
        app.assertBoardButton("adv")
        app.assertBoardButton("an")
        app.assertBoardButton("b")
        app.assertBoardButton("bant")
        app.assertBoardButton("c")
        app.assertBoardButton("cgl")
        app.assertBoardButton("ck")
        app.assertBoardButton("cm")
        // app.assertBoardButton("co")
        // app.assertBoardButton("d")
        // app.assertBoardButton("diy")
    }

    func testAppLoadsOPPosts() throws {
        app.goToBoard("a")
        app.assertOpButton(0)
        app.assertOpButton(1)
        app.assertOpButton(2)
        app.assertOpButton(3)
        // app.assertOPThread(4)
        // app.assertOPThread(5)
    }

    func testAppLoadsPosts() throws {
        app.goToBoard("a")
        app.goToOPThread(0)

        app.assertPost(0)
        app.assertPost(1)
    }

    func xtestImageDownloaderSavesFiles() throws {
        app.goToBoard("a")
        app.goToOPThread(0)
        app.assertPost(0)
        app.tapThumbnailMedia(0)
        app.longPressGalleryMedia(0)
        app.tapSaveToPhotosButton()
        app.assertSuccessToastImage()
    }

    func xtestImageCopierCopiesUrlToPasteboard() throws {
        app.goToBoard("a")
        app.goToOPThread(0)
        app.assertPost(0)
        app.tapThumbnailMedia(0)
        app.longPressGalleryMedia(0)
        app.tapCopyToPasteboardButton()
        XCTAssert(UIPasteboard.general.hasURLs)
    }
}
