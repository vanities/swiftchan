//
//  VLCVideoViewModel.swift
//  swiftchan
//
//  Created by vanities on 2/1/21.
//

import SwiftUI
import MobileVLCKit

class VLCVideoViewModel: ObservableObject {
    @Published var vlcVideo: VLCVideo = VLCVideo()

    // MARK: Private

    func setCachedMediaPlayer(url: URL) {
        CacheManager.shared.getFileWith(stringUrl: url.absoluteString) { result in
            switch result {
            case .success(let url):
                DispatchQueue.main.async { [weak self] in
                    self?.vlcVideo.cachedUrl = url
                }
            case .failure(let error):
                debugPrint(error, " failure in the Cache of video")
            }
        }
    }
}
