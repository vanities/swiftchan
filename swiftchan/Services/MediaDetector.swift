//
//  MediaDetector.swift
//  swiftchan
//
//  Created by vanities on 11/7/20.
//

import Foundation

enum MediaType {
    case image
    case webm
    case gif
    case none
}

struct MediaDetector {
    static func detect(url: URL) -> MediaType {
        if url.absoluteString.hasSuffix("jpg") ||
            url.absoluteString.hasSuffix("jpeg") ||
            url.absoluteString.hasSuffix("png") {
            return .image
        } else if url.absoluteString.hasSuffix("gif") {
            return .gif
        } else if url.absoluteString.hasSuffix("webm") {
            return .webm
        } else {
            print("Error! cannot detect media extension", url)
            return .none
        }
    }
}
