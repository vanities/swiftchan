//
//  AccessibilityIdentifiers.swift
//  AccessibilityIdentifiers
//
//  Created on 8/26/21.
//

import Foundation

class AccessibilityIdentifiers {
    static func boardButton(_ name: String) -> String {
        "\(name) Board Button"
    }
    static func opButton(_ index: Int) -> String {
        "\(index) Thread Button"
    }
    static func postText(_ index: Int) -> String {
        "\(index) Post Text"
    }
    static func thumbnailMediaImage(_ index: Int) -> String {
        "\(index) Thumbnail Media Image"
    }
    static func galleryMediaImage(_ index: Int) -> String {
        "\(index) Gallery Media Image"
    }
    static let saveToPhotosButton: String = "Save to Photos Button"
    static let saveToFilesButton: String = "Save to Files Button"
    static let copyToPasteboardButton: String = "Copy to Pasteboard Button"
    static let successToastText: String = "Success Toast Text"

}
