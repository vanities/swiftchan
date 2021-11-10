//
//  GalleryViewModel.swift
//  swiftchan
//
//  Created by Adam Mischke on 11/4/21.
//

import SwiftUI

class Media: ObservableObject, Identifiable {
    var id: Int

    enum Format {
        case image, gif, webm, none
    }

    let format: Format
    @Published var url: URL
    let thumbnailUrl: URL
    var isSelected: Bool = false

    init(id: Int, url: URL, thumbnailUrl: URL) {
        self.id = id
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

extension Media: Hashable {
    public func hash(into hasher: inout Hasher) {
         hasher.combine(ObjectIdentifier(self))
    }
}
