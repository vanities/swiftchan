//
//  MediaView.swift
//  swiftchan
//
//  Created by vanities on 11/11/20.
//

import SwiftUI
import Kingfisher

struct MediaView: View {
    @EnvironmentObject var threadViewModel: ThreadView.ViewModel
    let index: Int
    @State var playWebm: Bool = false

    var onMediaChanged: ((Bool) -> Void)?

    @ViewBuilder
    var body: some View {
        let media = threadViewModel.media[index]

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
                    play: $playWebm
                )
                    .onSeekChanged { seeking in
                        onMediaChanged?(seeking)
                    }
                    .onChange(of: threadViewModel.media[index].isSelected) { selected in
                        playWebm = selected
                    }
                    .onAppear {
                        playWebm = threadViewModel.media[index].isSelected
                    }
            }
        case .gif:
            KFAnimatedImage(media.url)
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
                index: 0
            )
                .environmentObject(viewModel)
            MediaView(
                index: 1
            )
                .environmentObject(viewModel)
            MediaView(
                index: 2
            )
                .environmentObject(viewModel)
        }
    }
}
#endif
