import XCTest

@MainActor
final class BrowsingUITests: XCTestCase {
    func testDuoWorkspaceSurvivesBackgroundActivation() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["DUO_CAPTURE"] == "1",
                          "Run on Duo's open inner display.")
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = launchThreadFixture(extraArguments: ["--ui-media-fixture", "--ui-catalog-fixture"])
        app.buttons["Open Link Button"].tap()
        let link = app.textFields["Open Link URL"]
        XCTAssertTrue(link.waitForExistence(timeout: 5))
        link.tap()
        link.typeText("https://boards.4chan.org/biz/")
        app.buttons["Open Link Confirm"].tap()
        XCTAssertTrue(app.buttons["CatalogThread200"].waitForExistence(timeout: 10))
        app.buttons["CatalogThread200"].tap()
        XCTAssertTrue(app.staticTexts["#200"].waitForExistence(timeout: 10))
        let workspace = app.descendants(matching: .any)["BoardThreadWorkspace"].firstMatch
        XCTAssertTrue(workspace.exists)
        let readingAnchor = app.staticTexts["#205"]
        for _ in 0..<12 {
            if readingAnchor.isHittable { break }
            app.scrollViews["CatalogThreadDetail"].swipeUp()
        }
        XCTAssertTrue(readingAnchor.isHittable)
        captureDuo(app, "workspace-before-background")
        XCUIDevice.shared.press(.home)
        app.activate()
        captureDuo(app, "workspace-after-background")
        XCTAssertTrue(workspace.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["CatalogThread200"].isHittable)
        XCTAssertTrue(readingAnchor.waitForExistence(timeout: 10))
        XCTAssertTrue(readingAnchor.isHittable)
    }

    func testFoldedWorkspaceKeepsThreadBeyondHinge() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["DUO_CAPTURE"] == "1"
                          && ProcessInfo.processInfo.environment["DUO_FOLDED"] == "1",
                          "Run with the Duo's active vertical 40-point hinge region.")
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = launchThreadFixture(extraArguments: ["--ui-media-fixture", "--ui-catalog-fixture"])
        app.buttons["Open Link Button"].tap()
        let link = app.textFields["Open Link URL"]
        XCTAssertTrue(link.waitForExistence(timeout: 5))
        link.tap()
        link.typeText("https://boards.4chan.org/biz/")
        app.buttons["Open Link Confirm"].tap()
        let boardRow = app.buttons["CatalogThread100"]
        XCTAssertTrue(boardRow.waitForExistence(timeout: 10))
        boardRow.tap()
        XCTAssertTrue(app.staticTexts["#100"].waitForExistence(timeout: 10))
        let detail = app.thumbnailMediaImage(0)
        XCTAssertTrue(detail.exists)
        print("DUO_WORKSPACE_FRAMES: board=\(boardRow.frame); detail=\(detail.frame)")
        captureDuo(app, "folded-hinge-workspace")
        XCTAssertLessThanOrEqual(boardRow.frame.maxX, 455.5,
                                 "Keep board rows before the active hinge region.")
        XCTAssertGreaterThanOrEqual(detail.frame.minX, 495.5,
                                    "The selected thread must begin beyond the active hinge region.")
    }

    func testDuoWalkthroughAndGallery() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["DUO_CAPTURE"] == "1", "Run on an open Duo with TEST_RUNNER_DUO_CAPTURE=1.")
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = launchThreadFixture(extraArguments: ["--ui-media-fixture", "--ui-catalog-fixture", "-showGalleryPreview", "YES"])
        captureDuo(app, "01-boards")
        app.buttons["Favorites"].tap()
        captureDuo(app, "02-favorites")
        app.buttons["Settings"].tap()
        captureDuo(app, "03-settings")
        app.buttons["Filters & Highlights"].tap()
        captureDuo(app, "04-filters")
        app.buttons["Boards"].tap()
        app.buttons["Open Link Button"].tap()
        let boardLink = app.textFields["Open Link URL"]
        XCTAssertTrue(boardLink.waitForExistence(timeout: 5))
        boardLink.tap()
        boardLink.typeText("https://boards.4chan.org/biz/")
        app.buttons["Open Link Confirm"].tap()
        XCTAssertTrue(app.buttons["CatalogThread100"].waitForExistence(timeout: 10))
        app.buttons["CatalogThread100"].tap()
        XCTAssertTrue(app.staticTexts["#100"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any)["BoardThreadWorkspace"].firstMatch.exists)
        captureDuo(app, "04b-board-and-thread")
        app.buttons["CatalogThread200"].tap()
        XCTAssertTrue(app.staticTexts["#200"].waitForExistence(timeout: 10))
        captureDuo(app, "04c-switch-thread")
        app.buttons["Back to boards"].tap()
        openFixtureThread(in: app)
        captureDuo(app, "05-thread")
        app.tapThumbnailMedia(0)
        XCTAssertTrue(app.buttons["Close gallery"].waitForExistence(timeout: 10))
        captureDuo(app, "06-gallery")
        app.galleryMediaImage(0).tap()
        captureDuo(app, "07-gallery-filmstrip")
        app.galleryMediaImage(0).swipeUp()
        XCTAssertTrue(app.galleryMediaImage(1).waitForExistence(timeout: 10))
        XCTAssertTrue(app.galleryMediaImage(1).isHittable)
        captureDuo(app, "08-gallery-next-image")
        app.buttons["Close gallery"].tap()
        app.buttons["Follow This General"].tap()
        captureDuo(app, "09-follow-general")
        app.buttons["Cancel"].tap()
        app.buttons["Post Options 100"].tap()
        captureDuo(app, "10-post-actions")
    }

    private func captureDuo(_ app: XCUIApplication, _ name: String) {
        print("DUO_CAPTURE:swiftchan-\(name)")
        Thread.sleep(forTimeInterval: 4)
        attachScreenshot("Duo \(name)")
    }

    func testQuotePreviewChainDismissesBackToReadingPosition() {
        let app = launchThreadFixture(extraArguments: ["--ui-quote-fixture"])
        openFixtureThread(in: app, anchor: "#p105")
        app.links[">>104"].tap()
        XCTAssertTrue(app.navigationBars["#104"].waitForExistence(timeout: 5))
        app.scrollViews["Quote Preview 104"].links[">>103"].tap()
        XCTAssertTrue(app.navigationBars["#103"].waitForExistence(timeout: 5))
        attachScreenshot("Quote Chain Preview")
        app.navigationBars["#103"].buttons["Close Quote Preview"].tap()
        XCTAssertTrue(app.staticTexts["#105"].isHittable)
    }

    func testArchivedGeneralFindsNewerThread() {
        let app = launchThreadFixture(extraArguments: ["--ui-general-rollover"])
        openFixtureThread(in: app)
        app.buttons["Follow This General"].tap()
        app.buttons["Save General"].tap()
        app.buttons["Find Next General"].tap()
        app.buttons["Precious Metals General"].tap()
        XCTAssertTrue(app.staticTexts["#200"].waitForExistence(timeout: 10))
        attachScreenshot("Next General")
    }

    func testBoardFilterHidesMatchingPostInClassicCompactTheme() {
        let app = launchThreadFixture(rememberProgress: false, extraArguments: ["-chanTheme", "Yotsuba B", "-compactPosts", "YES"])
        app.buttons["Settings"].tap()
        app.buttons["Filters & Highlights"].tap()
        app.textFields["Filter Board"].tap()
        app.textFields["Filter Board"].typeText("biz")
        app.textFields["Filter Pattern"].tap()
        app.textFields["Filter Pattern"].typeText("Reply 100.")
        app.buttons["Add Filter"].tap()
        app.buttons["Boards"].tap()
        openFixtureThread(in: app)
        XCTAssertTrue(app.staticTexts["#101"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["#100"].exists)
        attachScreenshot("Yotsuba B Compact Filtered Thread")
    }

    func testReplyDraftQuotesPostAndWatcherChecksSavedThread() {
        let app = launchThreadFixture(seedProgress: true)
        openFixtureThread(in: app, anchor: "#p105")
        app.buttons["Toggle Thread Favorite"].tap()
        app.buttons["Post Options 105"].tap()
        app.buttons["Draft Reply To Post"].tap()
        let draft = app.textViews["Reply Draft"]
        XCTAssertTrue(draft.waitForExistence(timeout: 5))
        XCTAssertTrue((draft.value as? String ?? "").contains(">>105"))
        attachScreenshot("Quoted Reply Draft")
        app.buttons["Done"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["Favorites"].tap()
        app.buttons["Thread Watcher"].tap()
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "unread")).firstMatch.waitForExistence(timeout: 5))
        attachScreenshot("Thread Watcher")
    }

    func testRecentThreadsResumePositionAndCanBeCleared() {
        let app = launchThreadFixture()
        openFixtureThread(in: app, anchor: "#p105")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["Recent Threads"].tap()
        let recent = app.buttons["Recent Thread biz/100"]
        XCTAssertTrue(recent.waitForExistence(timeout: 5))
        attachScreenshot("Recent Threads")
        recent.tap()
        XCTAssertTrue(app.staticTexts["#105"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["#105"].isHittable)
        XCTAssertFalse(app.staticTexts["#100"].isHittable)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["Clear Recent Threads"].tap()
        app.buttons["Clear All"].tap()
        XCTAssertTrue(app.staticTexts["No Recent Threads"].waitForExistence(timeout: 5))
    }

    func testRecentThreadsDoNotCollectWhenRememberingIsDisabled() {
        let app = launchThreadFixture(rememberProgress: false)
        openFixtureThread(in: app)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["Recent Threads"].tap()
        XCTAssertTrue(app.staticTexts["No Recent Threads"].waitForExistence(timeout: 5))
    }

    func testSaveReplyAndReopenExactPostFromFavorites() {
        let app = launchThreadFixture(rememberProgress: false)
        openFixtureThread(in: app, anchor: "#p105")
        app.buttons["Post Options 105"].tap()
        app.buttons["Save Selected Reply"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["Favorites"].tap()
        app.buttons["Saved Replies"].tap()
        XCTAssertTrue(app.staticTexts["/biz/ · #105"].waitForExistence(timeout: 5))
        attachScreenshot("Saved Reply Text")
        app.buttons["Open Saved Reply 105"].tap()
        XCTAssertTrue(app.staticTexts["#105"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["#105"].isHittable)
        XCTAssertFalse(app.staticTexts["#100"].isHittable)
        app.buttons["Post Options 105"].tap()
        XCTAssertEqual(app.buttons["Save Selected Reply"].label, "Remove Saved Reply")
        app.buttons["Save Selected Reply"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["No Saved Replies"].waitForExistence(timeout: 5))
    }

    func testJumpBetweenFirstPostAndLatestReply() {
        let app = launchThreadFixture(rememberProgress: false)
        openFixtureThread(in: app)
        XCTAssertTrue(app.staticTexts["#100"].isHittable)
        app.buttons["Thread Jump Menu"].tap()
        app.buttons["Jump To Latest Reply"].tap()
        XCTAssertTrue(app.staticTexts["#114"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["#114"].isHittable)
        XCTAssertFalse(app.staticTexts["#100"].isHittable)
        attachScreenshot("Jump To Latest Reply")
        app.buttons["Post Options 114"].tap()
        app.buttons["Hide Selected Post"].tap()
        XCTAssertTrue(app.buttons["Undo Hide"].waitForExistence(timeout: 5))
        app.buttons["Thread Jump Menu"].tap()
        app.buttons["Jump To First Post"].tap()
        XCTAssertTrue(app.staticTexts["#100"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["#100"].isHittable)
        XCTAssertFalse(app.staticTexts["#114"].isHittable)
        app.buttons["Thread Jump Menu"].tap()
        app.buttons["Jump To Latest Reply"].tap()
        XCTAssertTrue(app.staticTexts["#113"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["#113"].isHittable)
        XCTAssertFalse(app.staticTexts["#114"].exists)
    }

    func testFavoritesBackupShowsSavedGeneralAndOpensExport() {
        let app = launchApp()
        app.buttons["Settings"].tap()
        app.buttons["Manage Favorites Backup"].tap()
        XCTAssertTrue(app.buttons["Export Favorites"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Export Favorites"].isEnabled)
        XCTAssertTrue(app.buttons["Import Favorites"].isEnabled)
        app.buttons["Favorites"].tap()
        app.buttons["Follow General Button"].tap()
        fillGeneral(in: app, name: "Precious Metals General")
        app.buttons["Save General"].tap()
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.buttons["Export Favorites"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Export Favorites"].isEnabled)
        attachScreenshot("Favorites Backup")
        app.buttons["Export Favorites"].tap()
        XCTAssertTrue(app.buttons["Save"].waitForExistence(timeout: 10))
        attachScreenshot("Export Favorites In Files")
    }

    func testFollowNamedGeneralDirectlyFromFavoritesAndEditIt() {
        let app = launchApp()
        app.buttons["Favorites"].tap()
        app.buttons["Follow General Button"].tap()
        fillGeneral(in: app, name: "Precious Metals General")
        attachScreenshot("Follow Precious Metals General")
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
        // A literal marker avoids autocorrection and does not assume cursor placement.
        name.typeText("12345")
        let edited = NSPredicate(format: "value CONTAINS %@", "12345")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: edited, object: name)], timeout: 10), .completed)
        let editedName = name.value as? String ?? ""
        XCTAssertTrue(editedName.contains("12345"))
        XCTAssertNotEqual(editedName, "Metals Watch")
        app.buttons["Save General"].tap()
        XCTAssertTrue(app.staticTexts[editedName].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts.matching(identifier: "/biz/ · /pmg/").count, 1)
        attachScreenshot("Followed General")
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
        attachScreenshot("Invalid Link Feedback")
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
        attachScreenshot("Follow From Thread")
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
        attachScreenshot("Restored Position And Unread Replies")
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
        attachScreenshot("Reopened At Saved Position")
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

    func testHideReplyCanBeUndoneImmediately() {
        let app = launchThreadFixture()
        openFixtureThread(in: app, anchor: "#p105")
        app.buttons["Post Options 105"].tap()
        XCTAssertTrue(app.buttons["Hide Selected Post"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Share Selected Post"].isHittable)
        attachScreenshot("Post Sharing Options")
        app.buttons["Hide Selected Post"].tap()
        XCTAssertTrue(app.buttons["Undo Hide"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["#105"].exists)
        attachScreenshot("Hidden Reply With Undo")
        app.buttons["Undo Hide"].tap()
        XCTAssertTrue(app.staticTexts["#105"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Undo Hide"].exists)
    }

    func testHiddenThreadCanBeRestoredFromSettings() {
        let app = launchThreadFixture()
        openFixtureThread(in: app)
        app.buttons["Post Options 100"].tap()
        XCTAssertTrue(app.buttons["Hide Selected Post"].waitForExistence(timeout: 5))
        app.buttons["Hide Selected Post"].tap()
        XCTAssertTrue(app.buttons["Undo Hide"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["#100"].exists)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["Settings"].tap()
        app.buttons["Manage Hidden Posts"].tap()
        let restore = app.buttons["Restore Hidden biz/100"]
        XCTAssertTrue(restore.waitForExistence(timeout: 5))
        attachScreenshot("Manage Hidden Threads")
        restore.tap()
        XCTAssertTrue(app.staticTexts["Nothing Hidden"].waitForExistence(timeout: 5))
        app.buttons["Boards"].tap()
        openFixtureThread(in: app, anchor: "#p100")
        XCTAssertTrue(app.staticTexts["#100"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["#100"].isHittable)
    }

    private func launchThreadFixture(seedProgress: Bool = false, rememberProgress: Bool = true, extraArguments: [String] = []) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-thread-fixture", "-biometricsEnabled", "NO", "-rememberThreadPositions", rememberProgress ? "YES" : "NO"]
        if seedProgress { app.launchArguments.append("--ui-reading-seed") }
        app.launchArguments += extraArguments
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
        let completeName = NSPredicate(format: "value == %@", name)
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: completeName, object: nameField(in: app))], timeout: 10), .completed)
        XCTAssertTrue(app.buttons["Save General"].isEnabled)
    }

    private func nameField(in app: XCUIApplication) -> XCUIElement {
        let field = app.textFields["General Name"]
        return field.exists ? field : app.textViews["General Name"]
    }

    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
