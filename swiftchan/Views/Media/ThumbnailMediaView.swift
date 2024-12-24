//
//  ThumbnailMediaView.swift
//  swiftchan
//
//  Created by vanities on 11/15/20.
//

import SwiftUI
import Kingfisher

struct ThumbnailMediaView: View {
    let url: URL
    let thumbnailUrl: URL
    @AppStorage("fullImagesForThumbanails") var fullImageForThumbnails = true
    @AppStorage("showGifThumbnails") var showGifThumbnails = true

    @ViewBuilder
    var body: some View {
        Group {
            // Main Media Content
            switch Media.detect(url: url) {
            case .image:
                if fullImageForThumbnails {
                    ImageView(url: url, canGesture: false)
                } else {
                    ImageView(url: thumbnailUrl, canGesture: false)
                }
            case .webm, .mp4:
                ZStack {
                    ImageView(url: thumbnailUrl, canGesture: false)
                    Image(systemName: "play.circle")
                        .imageScale(.large)
                        .foregroundColor(.white)
                }
            case .gif:
                if showGifThumbnails {
                    GIFView(url: url)
                        .scaledToFit()
                } else {
                    ImageView(url: thumbnailUrl, canGesture: false)
                }
            case .none:
                EmptyView()
            }
        }
        .overlay (
                ZStack {
                    if Date.isFourchanBday() {
                        Image("PartyHat")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .offset(x: -25, y: -80)
                    }
                    if Date.isChristmas() {
                        Image("SantaHat")
                            .frame(width: 100, height: 100)
                            .offset(x: -25, y: -80)
                    }
            }, alignment: .topLeading
            )
    }
}

#if DEBUG
#Preview {
    Group {
        ThumbnailMediaView(url: URLExamples.image,
                           thumbnailUrl: URLExamples.image)
        ThumbnailMediaView(url: URLExamples.gif,
                           thumbnailUrl: URLExamples.gif)
    }
}
#endif
