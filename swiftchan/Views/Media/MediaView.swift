//
//  MediaView.swift
//  swiftchan
//
//  Created by vanities on 11/11/20.
//

import SwiftUI

struct MediaView: View {
    @Binding var selected: Bool
    let url: URL

    var onMediaChanged: ((Bool) -> Void)?

    @ViewBuilder
    var body: some View {
        switch MediaDetector.detect(url: url) {
        case .image:
            ImageView(url: self.url, canGesture: true, isSelected: self.$selected)
                .onZoomChanged { zoomed in
                    self.onMediaChanged?(zoomed)
                }
        case .webm:
            VLCContainerView(url: self.url,
                             play: self.$selected
            )
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
            MediaView(
                selected: .constant(true),
                url: URLExamples.image
            )
            MediaView(
                selected: .constant(true),
                url: URLExamples.gif
            )
            MediaView(
                selected: .constant(true),
                url: URLExamples.webm
            )
        }
    }
}
