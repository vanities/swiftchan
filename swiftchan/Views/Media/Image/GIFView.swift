//
//  GIFView.swift
//  swiftchan
//
//  Created by Adam Mischke on 9/4/22.
//

import SwiftUI
import Kingfisher

struct GIFView: View {
    let url: URL

    var body: some View {
        return KFAnimatedImage(url)
            .placeholder { progress in
                ProgressView(progress)
                    .progressViewStyle(WhiteCircularProgressViewStyle())
            }
    }
}
