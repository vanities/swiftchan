//
//  ThumbnailMediaView.swift
//  swiftchan
//
//  Created by vanities on 11/15/20.
//

import SwiftUI
import Defaults
import Kingfisher

struct ThumbnailMediaView: View {
    let url: URL
    let thumbnailUrl: URL
    @Default(.fullImagesForThumbanails) var fullImageForThumbnails
    @Default(.showGifThumbnails) var showGifThumbnails

    @ViewBuilder
    var body: some View {
        switch Media.detect(url: url) {
        case .image:
            ZStack {
                if fullImageForThumbnails {
                    ImageView(url: url)
                } else {
                    ImageView(url: thumbnailUrl)
                }
            }
        case .webm:
            ZStack {
                ImageView(url: thumbnailUrl)
                Image(systemName: "play.circle")
                    .imageScale(.large)
                    .foregroundColor(.white)
            }
        case .gif:
            if showGifThumbnails {
                KFAnimatedImage(url)
                    .scaledToFit()
            } else {
                ImageView(url: thumbnailUrl)
            }
        case .none:
            EmptyView()
        }
    }
}

#if DEBUG
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
#endif
