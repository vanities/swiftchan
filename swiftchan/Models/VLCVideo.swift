//
//  VLCVideo.swift
//  swiftchan
//
//  Created on 5/1/21.
//

import SwiftUI
@preconcurrency import MobileVLCKit

struct VLCVideo: Equatable, Identifiable, Sendable {
    let id: String
    let url: URL
    let mediaControlState: MediaControlState
    let mediaPlayerState: VLCMediaPlayerState
    let mediaState: VLCMediaState
    let currentTime: VLCTime
    let remainingTime: VLCTime
    let totalTime: VLCTime
    let seeking: Bool
    let initializing: Bool
    let downloadProgress: Progress

    init(
        url: URL,
        mediaControlState: MediaControlState = .initialize,
        mediaPlayerState: VLCMediaPlayerState = .buffering,
        mediaState: VLCMediaState = .buffering,
        currentTime: VLCTime = VLCTime(int: 0),
        remainingTime: VLCTime = VLCTime(int: 0),
        totalTime: VLCTime = VLCTime(int: 0),
        seeking: Bool = false,
        initializing: Bool = true,
        downloadProgress: Progress = {
            let p = Progress()
            p.completedUnitCount = 0
            p.totalUnitCount = 1
            return p
        }()
    ) {
        self.id = url.lastPathComponent.components(separatedBy: ".")[0]
        self.url = url
        self.mediaControlState = mediaControlState
        self.mediaPlayerState = mediaPlayerState
        self.mediaState = mediaState
        self.currentTime = currentTime
        self.remainingTime = remainingTime
        self.totalTime = totalTime
        self.seeking = seeking
        self.initializing = initializing
        self.downloadProgress = downloadProgress
    }

    enum MediaControlState: Equatable, Hashable, Sendable {
        case play, resume, pause, seek(VLCTime), jump(MediaControlDirection, Int32), initialize
    }

    enum MediaControlDirection: String {
        case forward, backward
    }
}

extension VLCVideo: Hashable {
    static func == (lhs: VLCVideo, rhs: VLCVideo) -> Bool {
        lhs.url == rhs.url
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}

extension VLCVideo {
    func with(
        url: URL? = nil,
        mediaControlState: MediaControlState? = nil,
        mediaPlayerState: VLCMediaPlayerState? = nil,
        mediaState: VLCMediaState? = nil,
        currentTime: VLCTime? = nil,
        remainingTime: VLCTime? = nil,
        totalTime: VLCTime? = nil,
        seeking: Bool? = nil,
        initializing: Bool? = nil,
        downloadProgress: Progress? = nil
    ) -> VLCVideo {
        VLCVideo(
            url: url ?? self.url,
            mediaControlState: mediaControlState ?? self.mediaControlState,
            mediaPlayerState: mediaPlayerState ?? self.mediaPlayerState,
            mediaState: mediaState ?? self.mediaState,
            currentTime: currentTime ?? self.currentTime,
            remainingTime: remainingTime ?? self.remainingTime,
            totalTime: totalTime ?? self.totalTime,
            seeking: seeking ?? self.seeking,
            initializing: initializing ?? self.initializing,
            downloadProgress: downloadProgress ?? self.downloadProgress
        )
    }
}
