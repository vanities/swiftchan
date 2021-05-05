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
    var useThumbnailGif: Bool = true

    @ViewBuilder
    var body: some View {
        switch MediaDetector.detect(url: url) {
        case .image:
            ImageView(url: self.url)
        case .webm:
            ZStack {
                ImageView(url: self.thumbnailUrl)
                Image(systemName: "play.circle")
                    .imageScale(.large)
                    .foregroundColor(.white)
            }
        case .gif:
            if self.useThumbnailGif {
                ImageView(url: self.thumbnailUrl)
            } else {
                ImageView(url: self.url)
                    .scaledToFit()
            }
        case .none:
            EmptyView()
        }
    }
}

struct ThumbnailMediaView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ThumbnailMediaView(url: URLExamples.image,
                               thumbnailUrl: URLExamples.image)
            ThumbnailMediaView(url: URLExamples.gif,
                               thumbnailUrl: URLExamples.gif)
        }

    }
}
