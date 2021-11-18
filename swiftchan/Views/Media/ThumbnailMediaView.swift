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
        switch Media.detect(url: url) {
        case .image:
            ImageView(url: thumbnailUrl, canGesture: false)
        case .webm:
            ZStack {
                ImageView(url: thumbnailUrl, canGesture: false)
                Image(systemName: "play.circle")
                    .imageScale(.large)
                    .foregroundColor(.white)
            }
        case .gif:
            if useThumbnailGif {
                ImageView(url: thumbnailUrl, canGesture: false)
            } else {
                ImageView(url: url, canGesture: false)
                    .scaledToFit()
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
