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
        XCTAssertEqual(app.buttons.count, 16)
        app.assertBoard("3")
        app.assertBoard("a")
        app.assertBoard("aco")
        app.assertBoard("adv")
        app.assertBoard("an")
        app.assertBoard("b")
        app.assertBoard("bant")
        app.assertBoard("c")
        app.assertBoard("cgl")
        app.assertBoard("ck")
        app.assertBoard("cm")
        app.assertBoard("co")
        app.assertBoard("d")
        app.assertBoard("diy")
    }

    func testAppLoadsOPPosts() throws {
        app.goToBoard("3")
        app.assertOPThread(0)
        app.assertOPThread(1)
        app.assertOPThread(2)
        app.assertOPThread(3)
        // app.assertOPThread(4)
        // app.assertOPThread(5)
    }

    func testAppLoadsPosts() throws {
        app.goToBoard("3")
        app.goToOPThread(0)

        app.assertPost(0)
        app.assertPost(1)
    }

    func testLaunchPerformance() throws {
        app.terminate()
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
    }

    func testBoardsScrollPerformance() throws {
        let measureOptions = XCTMeasureOptions()
        measureOptions.invocationOptions = [.manuallyStop]

        measure(metrics: [XCTOSSignpostMetric.scrollingAndDecelerationMetric], options: measureOptions) {
            app.swipeUp(velocity: .fast)
            stopMeasuring()
            app.swipeDown(velocity: .fast)
        }
    }

    func testCatalogScrollPerformance() throws {
        let measureOptions = XCTMeasureOptions()
        measureOptions.invocationOptions = [.manuallyStop]

        app.goToBoard("3")

        measure(metrics: [XCTOSSignpostMetric.scrollingAndDecelerationMetric], options: measureOptions) {
            app.swipeUp(velocity: .fast)
            stopMeasuring()
            app.swipeDown(velocity: .fast)
        }
    }

    func testPostScrollPerformance() throws {
        let measureOptions = XCTMeasureOptions()
        measureOptions.invocationOptions = [.manuallyStop]

        app.goToBoard("3")
        app.goToOPThread(0)

        measure(metrics: [XCTOSSignpostMetric.scrollingAndDecelerationMetric], options: measureOptions) {
            app.swipeUp(velocity: .fast)
            stopMeasuring()
            app.swipeDown(velocity: .fast)
        }
    }
}
