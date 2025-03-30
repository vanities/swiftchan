//
//  VLCVideoViewModel.swift
//  swiftchan
//
//  Created by vanities on 2/1/21.
//
import SwiftUI
import MobileVLCKit

@MainActor
@Observable
class VLCVideoViewModel {
    private(set) var video: VLCVideo

    init(url: URL) {
        video = VLCVideo(url: url)
    }

    func download() async throws {
        let cacheURL = CacheManager.shared.cacheURL(video.url)
        guard !CacheManager.shared.cacheHit(file: cacheURL) else {
            markDownloadFinished()
            return
        }

        debugPrint("Downloading webm: \(cacheURL)")
        let (tempURL, _) = try await URLSession.shared.download(from: video.url, progress: video.downloadProgress)
        debugPrint("Completed Downloading webm: \(cacheURL)")

        guard let cached = CacheManager.shared.cache(tempURL, cacheURL) else { return }

        // Update URL and mark download complete
        video = video.with(url: cached)
        markDownloadFinished()
    }

    private func markDownloadFinished() {
        video.downloadProgress.completedUnitCount = 1
        video.downloadProgress.totalUnitCount = 1
    }

    func updateTime(current: VLCTime, remaining: VLCTime) {
        video = video.with(currentTime: current, remainingTime: remaining)
    }

    func updateTime(current: VLCTime, remaining: VLCTime, total: VLCTime) {
        video = video.with(currentTime: current, remainingTime: remaining, totalTime: total)
    }

    func setSeeking(_ value: Bool) {
        video = video.with(seeking: value)
    }

    func setDoneInitializing() {
        video = video.with(initializing: false)
    }

    func setMediaControlState(_ state: VLCVideo.MediaControlState) {
        video = video.with(mediaControlState: state)
    }

    func setMediaPlayerState(_ state: VLCMediaPlayerState) {
        video = video.with(mediaPlayerState: state)
    }

    func setMediaState(_ state: VLCMediaState) {
        video = video.with(mediaState: state)
    }

    func play() {
        setMediaControlState(.play)
    }

    func pause() {
        setMediaControlState(.pause)
    }

    func resume() {
        setMediaControlState(.resume)
    }

    // These delegate methods don't really belong here now,
    // but leaving them in case you're registering this as a delegate somewhere
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        video.downloadProgress.completedUnitCount = totalBytesWritten
        video.downloadProgress.totalUnitCount = totalBytesExpectedToWrite
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // handled in download()
    }
}
