//
//  ThumbnailMediaView.swift
//  swiftchan
//
//  Created by vanities on 11/15/20.
//

import SwiftUI

struct ThumbnailMediaView: View {
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
            return AnyView(EmptyView())
            /*
         TODO: get webm thumbnails working
            return AnyView(
                VLCThumbnailView(url: self.url) { _ in
                    
                }
                )
 */
        case .gif:
            return AnyView(
                GIFView(url: self.url,
                        playGif: .constant(true))
                    .aspectRatio(contentMode: .fit)
            )
        case .none:
            return AnyView(EmptyView())
        }
    }
}

struct ThumbnailMediaView_Previews: PreviewProvider {
    static var previews: some View {
        ThumbnailMediaView(url: URL(string: "")!,
                  index: 0,
                  selected: true,
                  autoPlay: true)
    }
}
