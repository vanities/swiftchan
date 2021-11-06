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
    @State var isSelected: Bool
    @Binding var selected: Int
    let index: Int

    var onMediaChanged: ((Bool) -> Void)?

    init(selected: Binding<Int>, index: Int) {
        self._selected = selected
        self.index = index
        self._isSelected = State(initialValue: selected.wrappedValue == index)
    }

    @ViewBuilder
    var body: some View {
        let media = threadViewModel.media[index]

        switch media.format {
        case .image:
            ImageView(url: media.url, canGesture: true, isSelected: $isSelected)
                .onZoomChanged { zoomed in
                    onMediaChanged?(zoomed)
                }
                .onChange(of: selected) { value in
                    isSelected = value == index
                }
        case .webm:
            ZStack {
                ImageView(
                    url: media.thumbnailUrl,
                    canGesture: false,
                    isSelected: $isSelected
                )

                VLCContainerView(
                    url: media.url,
                    play: $isSelected
                )
                    .onSeekChanged { seeking in
                        onMediaChanged?(seeking)
                    }
                    .onChange(of: selected) { value in
                        isSelected = value == index
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
                selected: .constant(0),
                index: 0
            )
                .environmentObject(viewModel)
            MediaView(
                selected: .constant(1),
                index: 1
            )
                .environmentObject(viewModel)
            MediaView(
                selected: .constant(2),
                index: 2
            )
                .environmentObject(viewModel)
        }
    }
}
#endif
