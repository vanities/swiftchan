import XCTest

@MainActor
final class BrowsingUITests: XCTestCase {
    func testFollowNamedGeneralDirectlyFromFavoritesAndEditIt() {
        let app = launchApp()
        app.buttons["Favorites"].tap()
        app.buttons["Follow General Button"].tap()
        fillGeneral(in: app, name: "Precious Metals General")
        attachScreenshot("Follow Precious Metals General", app: app)
        app.buttons["Save General"].tap()
        XCTAssertTrue(app.staticTexts["Precious Metals General"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["/biz/ · /pmg/"].exists)

        // Following it again updates the existing entry instead of duplicating it.
        app.buttons["Follow General Button"].tap()
        fillGeneral(in: app, name: "Metals Watch")
        app.buttons["Save General"].tap()
        XCTAssertTrue(app.staticTexts["Metals Watch"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Precious Metals General"].exists)
        XCTAssertEqual(app.staticTexts.matching(identifier: "/biz/ · /pmg/").count, 1)
        let row = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Metals Watch")).firstMatch
        row.swipeRight()
        app.buttons["Edit"].tap()
        XCTAssertTrue(app.navigationBars["Edit General"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["General Board"].value as? String, "biz")
        XCTAssertEqual(app.textFields["General Tag"].value as? String, "/pmg/")
        XCTAssertEqual(nameField(in: app).value as? String, "Metals Watch")
        let name = nameField(in: app)
        name.tap()
        name.typeKey("a", modifierFlags: .command)
        name.typeText("Precious Metals General")
        app.buttons["Save General"].tap()
        XCTAssertTrue(app.staticTexts["Precious Metals General"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts.matching(identifier: "/biz/ · /pmg/").count, 1)
        attachScreenshot("Followed General", app: app)
    }

    func testOpenLinkRejectsUnrelatedURLWithoutNavigating() {
        let app = launchApp()
        XCTAssertTrue(app.buttons["Open Link Button"].waitForExistence(timeout: 5))
        app.buttons["Open Link Button"].tap()
        let field = app.textFields["Open Link URL"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("https://example.com")
        app.buttons["Open Link Confirm"].tap()
        XCTAssertTrue(app.staticTexts["Open Link Error"].waitForExistence(timeout: 5))
        attachScreenshot("Invalid Link Feedback", app: app)
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.buttons["Open Link Button"].waitForExistence(timeout: 5))
    }

    private func launchApp() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "-biometricsEnabled", "NO"]
        app.launch()
        return app
    }

    private func fillGeneral(in app: XCUIApplication, name: String) {
        let board = app.textFields["General Board"]
        XCTAssertTrue(board.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Save General"].isEnabled)
        board.tap()
        board.typeText("/biz/")
        app.textFields["General Tag"].tap()
        app.textFields["General Tag"].typeText("/pmg/")
        nameField(in: app).tap()
        nameField(in: app).typeText(name)
        XCTAssertTrue(app.buttons["Save General"].isEnabled)
    }

    private func nameField(in app: XCUIApplication) -> XCUIElement {
        let field = app.textFields["General Name"]
        return field.exists ? field : app.textViews["General Name"]
    }

    private func attachScreenshot(_ name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
