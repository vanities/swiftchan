//
//  VLCVideoViewModel.swift
//  swiftchan
//
//  Created by vanities on 2/1/21.
//
import SwiftUI
import MobileVLCKit

class VLCVideoViewModel: ObservableObject {
    @Published private(set) var vlcVideo = VLCVideo()

    func updateTime(current: VLCTime, remaining: VLCTime) {
        vlcVideo.currentTime = current
        vlcVideo.remainingTime = remaining
    }
    func updateTime(current: VLCTime, remaining: VLCTime, total: VLCTime) {
        vlcVideo.currentTime = current
        vlcVideo.remainingTime = remaining
        vlcVideo.totalTime = total
    }
    func setSeeking(_ value: Bool) {
        vlcVideo.seeking = value
    }
    func setDoneInitializing() {
        vlcVideo.initializing = false
    }
    func setMediaControlState(_ state: VLCVideo.MediaControlState) {
        vlcVideo.mediaControlState = state
    }
    func setMediaPlayerState(_ state: VLCMediaPlayerState) {
        vlcVideo.mediaPlayerState = state
    }
    func setMediaState(_ state: VLCMediaState) {
        vlcVideo.mediaState = state
    }
    func play() {
        setMediaControlState(.play)
    }
    func pause() {
        setMediaControlState(.pause)
    }
}
