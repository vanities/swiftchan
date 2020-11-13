//
//  MediaView.swift
//  swiftchan
//
//  Created by vanities on 11/11/20.
//

import SwiftUI

struct MediaView: View {
    let url: URL
    let index: Int
    let selected: Bool
    let autoPlay: Bool

    var body: some View {
        switch MediaDetector.detect(url: url) {
        case .image:
            return AnyView(
                ImageView(index: self.index,
                      url: self.url,
                      isSelected: self.selected)
        )
        case .webm:
            return AnyView(
                VLCContainerView(url: self.url,
                             autoPlay: true,
                             play: self.selected))
        case .gif:
            return AnyView(
                GIFView(url: self.url,
                        playGif: .constant(true)))
        case .none:
            return AnyView(EmptyView())
        }
    }
}

struct MediaView_Previews: PreviewProvider {
    static var previews: some View {
        MediaView(url: URL(string: "")!,
                  index: 0,
                  selected: true,
                  autoPlay: true)
    }
}
