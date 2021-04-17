//
//  VLCVideoViewModel.swift
//  swiftchan
//
//  Created by vanities on 2/1/21.
//

import SwiftUI
import MobileVLCKit

class VLCVideoViewModel: ObservableObject {
    enum MediaState: Equatable {
        case play
        case pause
        case seek(VLCTime)
    }

    @Published var url: URL?
    @Published var cachedUrl: URL?
    @Published var mediaState: MediaState = .pause
    @Published var state: VLCMediaPlayerState = .buffering
    @Published var currentTime: VLCTime = VLCTime(int: 0)
    @Published var remainingTime: VLCTime = VLCTime(int: 0)
    @Published var totalTime: VLCTime = VLCTime(int: 0)
    @Published var seeking: Bool = false

    // MARK: Private

    func setCachedMediaPlayer(url: URL) {
        CacheManager.shared.getFileWith(stringUrl: url.absoluteString) { result in
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    self.cachedUrl = url
                }
            case .failure(let error):
                print(error, " failure in the Cache of video")
            }
        }
    }
}
