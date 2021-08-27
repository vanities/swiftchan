//
//  swiftchanPerformanceTests.swift
//  swiftchanPerformanceTests
//
//  Created by vanities on 8/26/21.
//

import XCTest
@testable import swiftchan

class SwiftchanPerformanceTests: XCTestCase {
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
