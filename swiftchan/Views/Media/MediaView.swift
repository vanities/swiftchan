//
//  MediaView.swift
//  swiftchan
//
//  Created by vanities on 11/11/20.
//

import SwiftUI
import Kingfisher

struct MediaView: View {
    @State var isSelected: Bool
    @Binding var selected: Int
    let thumbnailUrl: URL
    let url: URL
    let id: Int

    var onMediaChanged: ((Bool) -> Void)?

    init(selected: Binding<Int>,
         thumbnailUrl: URL,
         url: URL,
         id: Int) {
        self._selected = selected
        self.thumbnailUrl = thumbnailUrl
        self.url = url
        self.id = id

        self._isSelected = State(initialValue: selected.wrappedValue == id)
    }

    @ViewBuilder
    var body: some View {
        switch MediaDetector.detect(url: url) {
        case .image:
            ImageView(url: url, canGesture: true, isSelected: $isSelected)
                .onZoomChanged { zoomed in
                    onMediaChanged?(zoomed)
                }
                .onChange(of: selected) { value in
                    isSelected = value == id
                }
        case .webm:
            ZStack {
                ImageView(url: thumbnailUrl, canGesture: false, isSelected: $isSelected)

                VLCContainerView(
                    thumbnailUrl: thumbnailUrl,
                    url: url,
                    play: $isSelected
                )
                    .onSeekChanged { seeking in
                        onMediaChanged?(seeking)
                    }
                    .onChange(of: selected) { value in
                        isSelected = value == id
                    }
            }
        case .gif:
            KFAnimatedImage(url)
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

struct MediaView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MediaView(
                selected: .constant(0),
                thumbnailUrl: URLExamples.image,
                url: URLExamples.image,
                id: 0
            )
            MediaView(
                selected: .constant(0),
                thumbnailUrl: URLExamples.image,
                url: URLExamples.gif,
                id: 0
            )
            MediaView(
                selected: .constant(0),
                thumbnailUrl: URLExamples.image,
                url: URLExamples.webm,
                id: 0
            )
        }
    }
}
