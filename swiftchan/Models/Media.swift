//
//  GalleryViewModel.swift
//  swiftchan
//
//  Created by Adam Mischke on 11/4/21.
//

import SwiftUI

struct Media {
    let index: Int
    let id: URL

    enum Format {
        case image, gif, webm, mp4, none
    }

    let format: Format
    var url: URL
    let thumbnailUrl: URL
    var isSelected: Bool = false

    init(index: Int, url: URL, thumbnailUrl: URL) {
        self.index = index
        self.id = url
        self.url = url
        self.thumbnailUrl = thumbnailUrl
        self.format = Media.detect(url: url)
    }

    static func detect(url: URL) -> Format {
        if url.absoluteString.hasSuffix("jpg") ||
            url.absoluteString.hasSuffix("jpeg") ||
            url.absoluteString.hasSuffix("png") {
            return .image
        } else if url.absoluteString.hasSuffix("gif") {
            return .gif
        } else if url.absoluteString.hasSuffix("webm") {
            return .webm
        } else if url.absoluteString.hasSuffix("mp4") {
            return .mp4
        } else {
            debugPrint("Error! cannot detect media extension", url)
            return .none
        }
    }
}

extension Media: Equatable {
    static func == (lhs: Media, rhs: Media) -> Bool {
        lhs.url == rhs.url
    }
}

extension Media: Identifiable, Hashable { }
