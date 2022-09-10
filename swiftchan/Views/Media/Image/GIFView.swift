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
    @State var progress = Progress()

    var body: some View {
        return KFAnimatedImage(url)
            .placeholder {
                ProgressView(progress)
                    .progressViewStyle(WhiteCircularProgressViewStyle())
            }
            .onProgress { receivedSize, totalSize  in
                progress.completedUnitCount = receivedSize
                progress.totalUnitCount = totalSize
            }
    }
}
