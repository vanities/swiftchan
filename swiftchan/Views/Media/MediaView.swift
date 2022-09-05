//
//  MediaView.swift
//  swiftchan
//
//  Created by vanities on 11/11/20.
//

import Foundation
import SwiftUI
import Kingfisher

struct MediaView: View {
    let media: Media
    var onMediaChanged: ((Bool) -> Void)?

    @ViewBuilder
    var body: some View {
        switch media.format {
        case .image:
            ImageView(url: media.url)
                .onZoomChanged { zoomed in
                    onMediaChanged?(zoomed)
                }
        case .webm:
            ZStack {
                ImageView(
                    url: media.thumbnailUrl,
                    canGesture: false
                )

                VLCContainerView(
                    url: media.url,
                    isSelected: media.isSelected
                )
            }
        case .gif:
            GIFView(url: media.url)
                .scaledToFit()
        case .none:
            EmptyView()
        }
    }
}

extension MediaView: Buildable {
    func onMediaChanged(_ callback: ((Bool) -> Void)?) -> Self {
        mutating(keyPath: \.onMediaChanged, value: callback)
    }
}

#if DEBUG
struct MediaView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ThreadView.ViewModel(boardName: "pol", id: 0)
        let urls = [
                URLExamples.image,
                URLExamples.gif,
                URLExamples.webm
            ]
        viewModel.setMedia(mediaUrls: urls, thumbnailMediaUrls: urls)

        return Group {
            MediaView(
                media: viewModel.media[0]
            )
            MediaView(
                media: viewModel.media[1]
            )
            MediaView(
                media: viewModel.media[2]
            )
        }
    }
}
#endif
