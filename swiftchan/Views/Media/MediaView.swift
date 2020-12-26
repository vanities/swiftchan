//
//  MediaView.swift
//  swiftchan
//
//  Created by vanities on 11/11/20.
//

import SwiftUI

struct MediaView: View {
    let url: URL
    let selected: Bool
    @Binding var mediaState: MediaState

    var onMediaChanged: ((Bool) -> Void)?

    @ViewBuilder
    var body: some View {
        switch MediaDetector.detect(url: url) {
        case .image:
            ImageView(url: self.url,
                      isSelected: self.selected,
                      canGesture: true)
                .onZoomChanged { zoomed in
                    self.onMediaChanged?(zoomed)
                }
        case .webm:
            VLCContainerView(url: self.url,
                             autoPlay: self.selected,
                             mediaState: self.$mediaState)
                .onSeekChanged { seeking in
                    self.onMediaChanged?(seeking)
                }
        case .gif:
            GIFView(url: self.url)
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
            MediaView(url: URLExamples.image,
                      selected: true,
                  mediaState: .constant(.play))
            MediaView(url: URLExamples.gif,
                      selected: true,
                      mediaState: .constant(.play))
            MediaView(url: URLExamples.webm,
                      selected: true,
                      mediaState: .constant(.play))
        }
    }
}
