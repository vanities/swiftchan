//
//  VLCVideoViewModel.swift
//  swiftchan
//
//  Created on 2/1/21.
//
import SwiftUI
import Combine
import MobileVLCKit

@MainActor
@Observable
class VLCVideoViewModel {
    private(set) var video: VLCVideo
    private var cancellables: Set<AnyCancellable> = []
    private var lastUpdateTime: Date = Date()
    private let updateThrottle: TimeInterval = 0.1 // Throttle updates to 10Hz

    // Direct reference to UIView for immediate command execution
    weak var vlcUIView: VLCMediaListPlayerUIView?

    init(url: URL) {
        video = VLCVideo(url: url)
        video.downloadProgress
            .publisher(for: \.fractionCompleted)
            .receive(on: RunLoop.main)
            .throttle(for: .milliseconds(50), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] fractionCompleted in
                guard let self else { return }
                // Force update for significant progress changes
                if fractionCompleted == 0.0 || fractionCompleted == 1.0 ||
                   abs(fractionCompleted - self.video.downloadProgress.fractionCompleted) > 0.05 {
                    debugPrint("📥 Download progress: \(Int(fractionCompleted * 100))%")
                }
                self.video = self.video.with(downloadProgress: self.video.downloadProgress)
            }
            .store(in: &cancellables)
    }

    func download() async throws {
        let cacheURL = CacheManager.shared.cacheURL(video.url)

        // Check cache first
        if CacheManager.shared.cacheHit(file: cacheURL) {
            if CacheManager.shared.isValidVideoFile(file: cacheURL) {
                video = video.with(url: cacheURL)
                markDownloadFinished()
                return
            } else {
                debugPrint("Invalid cached video, removing: \(cacheURL)")
                try? FileManager.default.removeItem(at: cacheURL)
            }
        }

        // Download with retry logic
        var retryCount = 0
        let maxRetries = 3

        while retryCount < maxRetries {
            do {
                debugPrint("Downloading webm (attempt \(retryCount + 1)): \(video.url)")
                let (tempURL, response) = try await URLSession.shared.download(from: video.url, progress: video.downloadProgress)

                // Verify response
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode != 200 {
                    throw URLError(.badServerResponse)
                }

                debugPrint("Download completed: \(cacheURL)")

                // Cache and validate
                guard let cached = CacheManager.shared.cache(tempURL, cacheURL) else {
                    throw URLError(.cannotCreateFile)
                }

                guard CacheManager.shared.isValidVideoFile(file: cached) else {
                    try? FileManager.default.removeItem(at: cached)
                    throw URLError(.cannotParseResponse)
                }

                // Success - update URL and mark complete
                video = video.with(url: cached)
                markDownloadFinished()
                return

            } catch {
                retryCount += 1
                if retryCount >= maxRetries {
                    debugPrint("Failed to download after \(maxRetries) attempts: \(error)")
                    throw error
                }

                // Exponential backoff
                let delay = Double(retryCount) * 1.0
                debugPrint("Retrying download in \(delay) seconds...")
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }

    private func markDownloadFinished() {
        video.downloadProgress.completedUnitCount = 1
        video.downloadProgress.totalUnitCount = 1
    }

    func updateTime(current: VLCTime, remaining: VLCTime) {
        // Remove throttling to ensure UI updates consistently  
        video = video.with(currentTime: current, remainingTime: remaining)
    }

    func updateTime(current: VLCTime, remaining: VLCTime, total: VLCTime) {
        // Debug every few updates to verify this is being called
        if current.intValue % 2000 == 0 && current.intValue > 0 {
            debugPrint("⏰ ViewModel updateTime called: \(current.description)")
        }

        // Remove throttling to ensure UI updates consistently
        video = video.with(currentTime: current, remainingTime: remaining, totalTime: total)
    }

    func setSeeking(_ value: Bool) {
        video = video.with(seeking: value)
    }

    func seek(to time: VLCTime) {
        debugPrint("🎮 VLCVideoViewModel.seek() called to: \(time.description)")

        // Try direct call first
        if let vlcUIView = vlcUIView {
            debugPrint("🎮 Calling seek directly")
            vlcUIView.seek(time: time)
        } else {
            debugPrint("🎮 Using state-based seek")
            setMediaControlState(.seek(time))
        }
    }

    func setDoneInitializing() {
        video = video.with(initializing: false)
    }

    func setMediaControlState(_ state: VLCVideo.MediaControlState) {
        // Prevent infinite loops by only updating if state actually changes
        guard video.mediaControlState != state else {
            debugPrint("🎮 State already set to: \(state)")
            return
        }
        debugPrint("🎮 Setting media control state to: \(state)")
        video = video.with(mediaControlState: state)

        // Force a UI update
        DispatchQueue.main.async {
            debugPrint("🎮 State change should trigger UI update now")
        }
    }

    func setMediaPlayerState(_ state: VLCMediaPlayerState) {
        if video.mediaPlayerState != state {
            debugPrint("🎮 Media player state changing: \(video.mediaPlayerState.rawValue) → \(state.rawValue)")
        }
        video = video.with(mediaPlayerState: state)
    }

    func setMediaState(_ state: VLCMediaState) {
        video = video.with(mediaState: state)
    }

    func play() {
        debugPrint("🎮 VLCVideoViewModel.play() called")

        // Try direct call first for immediate response
        if let vlcUIView = vlcUIView {
            debugPrint("🎮 Calling initializeAndPlay directly")
            vlcUIView.initializeAndPlay()
        } else {
            // Fallback to state-based approach
            debugPrint("🎮 Using state-based approach")
            setMediaControlState(.play)
        }
    }

    func pause() {
        debugPrint("🎮 VLCVideoViewModel.pause() called")

        // Try direct call first
        if let vlcUIView = vlcUIView {
            debugPrint("🎮 Calling pause directly")
            vlcUIView.pause()
        } else {
            debugPrint("🎮 Using state-based pause")
            setMediaControlState(.pause)
        }
    }

    func resume() {
        debugPrint("🎮 VLCVideoViewModel.resume() called")

        // Try direct call first
        if let vlcUIView = vlcUIView {
            debugPrint("🎮 Calling resume directly")
            vlcUIView.resume()
        } else {
            debugPrint("🎮 Using state-based resume")
            setMediaControlState(.resume)
        }
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
