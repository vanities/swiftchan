import XCTest

extension XCUIApplication {
    func tapElement(_ element: XCUIElement, _ timeout: TimeInterval = 1) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout))
        element.tap()
    }
    func longPressElement(_ element: XCUIElement, _ duration: TimeInterval = 0.5, _ timeout: TimeInterval = 1) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout))
        element.press(forDuration: duration)
    }
    func assertExistence(_ element: XCUIElement, _ timeout: TimeInterval = 1) {
        XCTAssert(element.waitForExistence(timeout: timeout), element.debugDescription)
    }

    func goToBoard(_ name: String) {
        tapElement(boardButton(name))
    }
    func goToOPThread(_ index: Int) {
        tapElement(opButton(index))
    }
    func tapThumbnailMedia(_ index: Int) {
        tapElement(thumbnailMediaImage(index))
    }
    func longPressGalleryMedia(_ index: Int) {
        longPressElement(galleryMediaImage(index))
    }
    func tapSaveToPhotosButton() {
        tapElement(saveToPhotosButton)
    }

    func assertBoardButton(_ name: String) {
        assertExistence(boardButton(name))
    }
    func assertOpButton(_ index: Int) {
        assertExistence(opButton(index))
    }
    func assertPost(_ index: Int) {
        assertExistence(postText(index))
    }
    func assertSuccessToastImage() {
        assertExistence(successToastImage)
    }
}
