//
//  ThumbnailMediaView.swift
//  swiftchan
//
//  Created by vanities on 11/15/20.
//

import SwiftUI

struct ThumbnailMediaView: View {
    let url: URL
    let thumbnailUrl: URL
    let index: Int
    let selected: Bool
    let autoPlay: Bool

    @ViewBuilder
    var body: some View {
        switch MediaDetector.detect(url: url) {
        case .image:
            ImageView(index: self.index,
                      url: self.url,
                      isSelected: self.selected)
        case .webm:
            ZStack {
                ImageView(index: self.index,
                          url: self.thumbnailUrl,
                          isSelected: self.selected)
                Image(systemName: "play.circle")
            }
        case .gif:
            GIFView(url: self.url,
                    playGif: .constant(true))
                .aspectRatio(contentMode: .fit)
        case .none:
            EmptyView()
        }
    }
}

struct ThumbnailMediaView_Previews: PreviewProvider {
    static var previews: some View {
        ThumbnailMediaView(url: URLExamples.image,
                           thumbnailUrl: URLExamples.image,
                           index: 0,
                           selected: true,
                           autoPlay: true)
    }
}
