//
//  VLCVideoViewModel.swift
//  swiftchan
//
//  Created by vanities on 2/1/21.
//
import SwiftUI
import MobileVLCKit

class VLCVideoViewModel: ObservableObject {
    @Published private(set) var video: VLCVideo

    init(url: URL) {
        video = VLCVideo(url: url)
    }

    func download() async throws {
        if let url = try? await video.download() {
            DispatchQueue.main.async {
                self.video.url = url
            }
        }
    }

    func updateTime(current: VLCTime, remaining: VLCTime) {
        video.currentTime = current
        video.remainingTime = remaining
    }
    func updateTime(current: VLCTime, remaining: VLCTime, total: VLCTime) {
        video.currentTime = current
        video.remainingTime = remaining
        video.totalTime = total
    }
    func setSeeking(_ value: Bool) {
        video.seeking = value
    }
    func setDoneInitializing() {
        video.initializing = false
    }
    func setMediaControlState(_ state: VLCVideo.MediaControlState) {
        video.mediaControlState = state
    }
    func setMediaPlayerState(_ state: VLCMediaPlayerState) {
        video.mediaPlayerState = state
    }
    func setMediaState(_ state: VLCMediaState) {
        video.mediaState = state
    }
    func play() {
        setMediaControlState(.play)
    }
    func pause() {
        setMediaControlState(.pause)
    }
}
