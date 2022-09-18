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
    @MainActor
    func download() async throws {
        if let url = try? await video.download() {
            DispatchQueue.main.async { [weak self] in
                self?.video.url = url
            }
        }
    }

    @MainActor
    func updateTime(current: VLCTime, remaining: VLCTime) {
        video.currentTime = current
        video.remainingTime = remaining
    }
    @MainActor
    func updateTime(current: VLCTime, remaining: VLCTime, total: VLCTime) {
        video.currentTime = current
        video.remainingTime = remaining
        video.totalTime = total
    }

    @MainActor
    func setSeeking(_ value: Bool) {
        video.seeking = value
    }
    @MainActor
    func setDoneInitializing() {
        video.initializing = false
    }
    @MainActor
    func setMediaControlState(_ state: VLCVideo.MediaControlState) {
        video.mediaControlState = state
    }
    @MainActor
    func setMediaPlayerState(_ state: VLCMediaPlayerState) {
        video.mediaPlayerState = state
    }
    @MainActor
    func setMediaState(_ state: VLCMediaState) {
        video.mediaState = state
    }
    @MainActor
    func play() {
        setMediaControlState(.play)
    }
    @MainActor
    func pause() {
        setMediaControlState(.pause)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        DispatchQueue.main.async { [weak self] in
            self?.video.downloadProgress.completedUnitCount = totalBytesWritten
            self?.video.downloadProgress.totalUnitCount = totalBytesExpectedToWrite
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        return
    }
}
