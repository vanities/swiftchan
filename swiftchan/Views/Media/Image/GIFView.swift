//
//  GIFView.swift
//  swiftchan
//
//  Created on 9/4/22.
//

import SwiftUI
import Kingfisher

struct GIFView: View {
    let url: URL

    var body: some View {
        return ZStack {
            KFAnimatedImage(url)
                .placeholder { progress in
                    ProgressView(progress)
                        .progressViewStyle(WhiteCircularProgressViewStyle())
                }
                .configure { view in
                    view.framePreloadCount = 3
                }
                .cacheOriginalImage()
            Color.white.opacity(0.001) // fixes tappable
        }

    }
}

#Preview {
    GIFView(url: URL(string: "https://media.tenor.com/E4oykP-erYMAAAAM/thistest-test.gif")!)
}
