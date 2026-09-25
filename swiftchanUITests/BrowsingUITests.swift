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
        name.typeText("Updated ")
        let editedName = name.value as? String ?? ""
        XCTAssertTrue(editedName.contains("Updated "))
        XCTAssertNotEqual(editedName, "Metals Watch")
        app.buttons["Save General"].tap()
        XCTAssertTrue(app.staticTexts[editedName].waitForExistence(timeout: 5))
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

    func testFollowGeneralFromThreadPrefillsFieldsAndPreservesCustomName() {
        let app = launchThreadFixture()
        openFixtureThread(in: app)
        app.buttons["Follow This General"].tap()
        XCTAssertEqual(app.textFields["General Board"].value as? String, "biz")
        XCTAssertEqual(app.textFields["General Tag"].value as? String, "/pmg/")
        XCTAssertEqual(nameField(in: app).value as? String, "Precious Metals General")
        let name = nameField(in: app)
        name.tap()
        name.typeText("My ")
        let customName = name.value as? String ?? ""
        XCTAssertTrue(customName.contains("My "))
        attachScreenshot("Follow From Thread", app: app)
        app.buttons["Save General"].tap()
        app.buttons["Follow This General"].tap()
        XCTAssertTrue(app.navigationBars["Edit General"].waitForExistence(timeout: 5))
        XCTAssertEqual(nameField(in: app).value as? String, customName)
        app.buttons["Cancel"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["Favorites"].tap()
        XCTAssertTrue(app.staticTexts[customName].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts.matching(identifier: "/biz/ · /pmg/").count, 1)
    }

    func testResumeUnreadJumpAndSavePositionOnReopeningThread() {
        let app = launchThreadFixture(seedProgress: true)
        openFixtureThread(in: app)
        let savedPost = app.staticTexts["#105"]
        XCTAssertTrue(savedPost.waitForExistence(timeout: 5))
        XCTAssertTrue(savedPost.isHittable)
        XCTAssertFalse(app.staticTexts["#100"].isHittable)
        let jump = app.buttons["Jump To Unread"]
        XCTAssertTrue(jump.waitForExistence(timeout: 5))
        attachScreenshot("Restored Position And Unread Replies", app: app)
        jump.tap()
        let scroll = app.scrollViews["Thread Posts"]
        for _ in 0..<10 where !app.staticTexts["#114"].isHittable { scroll.swipeUp() }
        XCTAssertTrue(app.staticTexts["#114"].isHittable)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        openFixtureThread(in: app)
        XCTAssertTrue(app.staticTexts["#114"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["#114"].isHittable)
        XCTAssertFalse(app.staticTexts["#100"].isHittable)
        XCTAssertFalse(app.buttons["Jump To Unread"].exists)
        attachScreenshot("Reopened At Saved Position", app: app)
    }

    func testPostLinkTakesPriorityOverRememberedPosition() {
        let app = launchThreadFixture(seedProgress: true)
        openFixtureThread(in: app, anchor: "#p112")
        XCTAssertTrue(app.staticTexts["#112"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["#112"].isHittable)
        XCTAssertFalse(app.staticTexts["#105"].isHittable)
    }

    func testRememberingCanBeDisabledWithoutRestoringOrShowingUnread() {
        let app = launchThreadFixture(seedProgress: true, rememberProgress: false)
        openFixtureThread(in: app)
        XCTAssertTrue(app.staticTexts["#100"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["#100"].isHittable)
        XCTAssertFalse(app.buttons["Jump To Unread"].exists)
    }

    private func launchThreadFixture(seedProgress: Bool = false, rememberProgress: Bool = true) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-thread-fixture", "-biometricsEnabled", "NO", "-rememberThreadPositions", rememberProgress ? "YES" : "NO"]
        if seedProgress { app.launchArguments.append("--ui-reading-seed") }
        app.launch()
        return app
    }

    private func openFixtureThread(in app: XCUIApplication, anchor: String = "") {
        XCTAssertTrue(app.buttons["Open Link Button"].waitForExistence(timeout: 5))
        app.buttons["Open Link Button"].tap()
        let field = app.textFields["Open Link URL"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("https://boards.4chan.org/biz/thread/100" + anchor)
        app.buttons["Open Link Confirm"].tap()
        XCTAssertTrue(app.buttons["Follow This General"].waitForExistence(timeout: 5))
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
