import XCTest

extension XCUIApplication {
    func tapElement(_ element: XCUIElement, _ timeout: TimeInterval = 10, errorMessage: String? = nil) {
        assertExistence(element, timeout, errorMessage: errorMessage ?? "Could not tap element! \(element.debugDescription)")
        element.firstMatch.tap()

    }
    func longPressElement(_ element: XCUIElement,
                          _ duration: TimeInterval = 0.5,
                          _ timeout: TimeInterval = 5,
                          errorMessage: String? = nil) {
        assertExistence(element, timeout, errorMessage: errorMessage ?? "Could not long press element! \(element.debugDescription)")
        element.press(forDuration: duration)
    }
    func assertExistence(_ element: XCUIElement, _ timeout: TimeInterval = 5, errorMessage: String? = nil) {
        XCTAssert(element.waitForExistence(timeout: timeout), errorMessage ?? "Could not assert element! \(element.debugDescription)")
    }

    func goToBoard(_ name: String) {
        tapElement(boardButton(name), errorMessage: "Could not go to /\(name)/ board!")
    }
    func goToOPThread(_ index: Int) {
        tapElement(opButton(index), errorMessage: "Could not go to \(index) op thread!")
    }
    func tapThumbnailMedia(_ index: Int) {
        tapElement(thumbnailMediaImage(index), errorMessage: "Could not tap \(index) thumbnail media!")
    }
    func longPressGalleryMedia(_ index: Int) {
        longPressElement(galleryMediaImage(index), errorMessage: "Could not long press \(index) gallery media!")
    }
    func tapSaveToPhotosButton() {
        tapElement(saveToPhotosButton, errorMessage: "Could not tap to save photos buttons!")
    }
    func tapCopyToPasteboardButton() {
        tapElement(copyToPasteboardButton, errorMessage: "Could not press copy to pasteboard button!")
    }

    func assertBoardButton(_ name: String) {
        assertExistence(boardButton(name), errorMessage: "Could not assert board button \(name)!")
    }
    func assertOpButton(_ index: Int) {
        assertExistence(opButton(index), errorMessage: "Could not assert op button \(index)!")
    }
    func assertPost(_ index: Int) {
        assertExistence(postText(index), errorMessage: "Could not assert post \(index)!")
    }
    func assertSuccessToastImage() {
        assertExistence(successToastImage, 1, errorMessage: "Could not assert success toast image!")
    }
}
