//
//  MediaDetector.swift
//  swiftchan
//
//  Created by vanities on 11/7/20.
//

import Foundation

struct MediaDetector {
    static func isImage(url: URL) -> Bool {
        return url.absoluteString.hasSuffix("jpg") ||
            url.absoluteString.hasSuffix("jpeg") ||
            url.absoluteString.hasSuffix("png")
    }

    static func isGIF(url: URL) -> Bool {
        return url.absoluteString.hasSuffix("gif")
    }

    static func isWebm(url: URL) -> Bool {
        return url.absoluteString.hasSuffix("webm")
    }
}
