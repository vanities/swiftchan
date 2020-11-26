//
//  MediaView.swift
//  swiftchan
//
//  Created by vanities on 11/11/20.
//

import SwiftUI

struct MediaView: View, Buildable {
    let url: URL
    let selected: Bool

    func onMediaChanged(_ callback: ((Bool) -> Void)?) -> Self {
        mutating(keyPath: \.onMediaChanged, value: callback)
    }
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
                             autoPlay: true,
                             play: self.selected)
        case .gif:
            GIFView(url: self.url)
        case .none:
            EmptyView()
        }
    }
}

struct MediaView_Previews: PreviewProvider {
    static var previews: some View {
        MediaView(url: URLExamples.image,
                  selected: true)
    }
}
