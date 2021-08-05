import XCTest

extension XCUIApplication {
    func goToBoard(_ name: String) {
        let element = self.buttons["\(name) Board"]
        if element.waitForExistence(timeout: 0.5) {
            element.tap()
        }
    }
    func goToOPThread(_ index: Int) {
        let element = self.buttons["\(index) Thread"]
        if element.waitForExistence(timeout: 0.5) {
            element.tap()
        }
    }

    func assertBoard(_ name: String) {
        let element = self.buttons["\(name) Board"]
        XCTAssert(element.waitForExistence(timeout: 0.1), "Checking Board #\(name)")
    }

    func assertOPThread(_ index: Int) {
        let element = self.buttons["\(index) Thread"]
        XCTAssert(element.waitForExistence(timeout: 1), "Checking Thread #\(index)")
    }

    func assertPost(_ index: Int) {
        let element = self.staticTexts["\(index) Post"]
        XCTAssert(element.waitForExistence(timeout: 1), "Checking Post #\(index)")
    }
}
