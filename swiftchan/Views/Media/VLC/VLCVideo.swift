//
//  VLCVideo.swift
//  swiftchan
//
//  Created by vanities on 1/27/21.
//

import SwiftUI
import MobileVLCKit

enum MediaState: Equatable {
    case play
    case pause
    case seek(VLCTime)
}

class VLCVideo: ObservableObject { // , Identifiable, Equatable {
    var url: URL?

    @Published var cachedUrl: URL?
    @Published var mediaState: MediaState = .pause
    @Published var state: VLCMediaPlayerState = VLCMediaPlayerState(rawValue: 0)!
    @Published var currentTime: VLCTime = VLCTime(int: 0)
    @Published var remainingTime: VLCTime = VLCTime(int: 0)
    @Published var totalTime: VLCTime = VLCTime(int: 0)
    @Published var seeking: Bool = false

    // MARK: Private

    func setCachedMediaPlayer(context: VLCVideoView.Context) {
        if let url = url {
            CacheManager.shared.getFileWith(stringUrl: url.absoluteString) { result in
                switch result {
                case .success(let url):
                    self.cachedUrl = url
                case .failure(let error):
                    print(error, " failure in the Cache of video")
                }
            }
        }
    }
}
