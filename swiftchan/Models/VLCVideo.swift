//
//  VLCVideo.swift
//  swiftchan
//
//  Created by vanities on 5/1/21.
//

import SwiftUI
import MobileVLCKit

struct VLCVideo: Identifiable {
    var id: URL?

    enum MediaControlState: Equatable, Hashable {
        case play
        case pause
        case seek(VLCTime)
        case jump(MediaControlDirection, Int32)

        static func == (lhs: MediaControlState, rhs: MediaControlState) -> Bool {
            lhs.hashValue == rhs.hashValue
        }
    }
    enum MediaControlDirection: String {
        case forward
        case backward
    }

    var url: URL?
    var mediaControlState: MediaControlState = .pause
    var mediaPlayerState: VLCMediaPlayerState = .buffering
    var mediaState: VLCMediaState = .buffering
    var currentTime: VLCTime = VLCTime(int: 0)
    var remainingTime: VLCTime = VLCTime(int: 0)
    var totalTime: VLCTime = VLCTime(int: 0)
    var seeking: Bool = false
}

extension VLCVideo: Hashable {
    static func == (lhs: VLCVideo, rhs: VLCVideo) -> Bool {
        lhs.url == rhs.url
    }
}
