//
//  XCUIApplication+Identifiers.swift
//  XCUIApplication+Identifiers
//
//  Created by vanities on 8/26/21.
//

import XCTest

extension XCUIApplication {
    func boardButton(_ name: String) -> XCUIElement {
        buttons[AccessibilityIdentifiers.boardButton(name)]
    }
    func opButton(_ index: Int) -> XCUIElement {
        buttons[AccessibilityIdentifiers.opButton(index)]
    }
    func thumbnailMediaImage(_ index: Int) -> XCUIElement {
        images[AccessibilityIdentifiers.thumbnailMediaImage(index)]
    }
    func postText(_ index: Int) -> XCUIElement {
        staticTexts[AccessibilityIdentifiers.postText(index)]
    }
    func galleryMediaImage(_ index: Int) -> XCUIElement {
        images[AccessibilityIdentifiers.galleryMediaImage(index)]
    }
    var saveToPhotosButton: XCUIElement { buttons[AccessibilityIdentifiers.saveToPhotosButton]
    }
    var saveToFilesButton: XCUIElement { buttons[AccessibilityIdentifiers.saveToFilesButton]
    }
    var copyToPasteboardButton: XCUIElement { buttons[AccessibilityIdentifiers.copyToPasteboardButton]
    }
    var successToastImage: XCUIElement {
        images[AccessibilityIdentifiers.successToastText]
    }
}
