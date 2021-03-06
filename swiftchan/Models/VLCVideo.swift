//
//  VLCVideo.swift
//  swiftchan
//
//  Created by vanities on 5/1/21.
//

import SwiftUI
import MobileVLCKit

struct VLCVideo {
    enum MediaControlState: Equatable {
        case play
        case pause
        case seek(VLCTime)
    }

    var url: URL?
    var cachedUrl: URL?
    var mediaControlState: MediaControlState = .pause
    var mediaPlayerState: VLCMediaPlayerState = .buffering
    var mediaState: VLCMediaState = .buffering
    var currentTime: VLCTime = VLCTime(int: 0)
    var remainingTime: VLCTime = VLCTime(int: 0)
    var totalTime: VLCTime = VLCTime(int: 0)
    var seeking: Bool = false
}
