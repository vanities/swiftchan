//
//  VLCMediaListPlayerUIView.swift
//  Updated for Safe Cleanup and Playback Retry
//

import UIKit
import MobileVLCKit

class VLCMediaListPlayerUIView: UIView, VLCMediaPlayerDelegate {
    private var _url: URL {
        let cacheURL = CacheManager.shared.cacheURL(url)
        if CacheManager.shared.cacheHit(file: cacheURL) {
            return cacheURL
        }
        debugPrint("📁 Cache miss for \(url.lastPathComponent), expected at: \(cacheURL.path)")
        return url
    }
    private var url: URL
    private weak var delegate: VLCMediaPlayerDelegate?
    let mediaListPlayer = VLCMediaListPlayer()
    var media: VLCMedia?
    private var currentMediaURL: URL?
    private var isBeingDeallocated = false

    init(url: URL, frame: CGRect = .zero) {
        self.url = url
        super.init(frame: frame)
    }

    /// Initialize the media with options and setup the media player.
    func initialize(url: URL) {
        guard currentMediaURL != url || mediaListPlayer.mediaPlayer.media == nil else { return }

        // Only reset if we're switching to a different URL
        if currentMediaURL != url {
            resetPlayer()
        }

        media = VLCMedia(url: url)
        if let media = media {
            media.addOption("-vv")

            // Use the original approach that was working
            mediaListPlayer.rootMedia = media
            mediaListPlayer.mediaPlayer.media = media
            mediaListPlayer.mediaPlayer.drawable = self
            mediaListPlayer.mediaPlayer.delegate = delegate
            mediaListPlayer.repeatMode = .repeatCurrentItem

            #if DEBUG
            mediaListPlayer.mediaPlayer.audio?.isMuted = true
            #endif
            currentMediaURL = url
        }
    }

    /// Safely stop playback and release current media.
    private func resetPlayer() {
        guard !isBeingDeallocated else { return }

        let cleanup = {
            // Detach the delegate and drawable first to avoid callbacks on
            // a deallocated object. Then stop playback and clear the media.
            self.mediaListPlayer.mediaPlayer.delegate = nil
            self.mediaListPlayer.mediaPlayer.drawable = nil
            if !self.isBeingDeallocated {
                self.mediaListPlayer.mediaPlayer.stop()
                self.mediaListPlayer.stop()
            }
            self.mediaListPlayer.mediaPlayer.media = nil
            self.mediaListPlayer.rootMedia = nil
            self.currentMediaURL = nil
        }

        if Thread.isMainThread {
            cleanup()
        } else {
            DispatchQueue.main.sync(execute: cleanup)
        }
    }

    /// Start playback immediately without delays.
    func initializeAndPlay(retryCount: Int = 0) {
        guard !isBeingDeallocated else { return }

        let fileURL = _url
        let fileExists = FileManager.default.fileExists(atPath: fileURL.path)
        let fileSizeValid = (try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64 ?? 0) ?? 0 > 0

        guard fileExists, fileSizeValid else {
            // Retry a few times with delay if file isn't ready yet
            if retryCount < 5 {
                debugPrint("⏳ File not ready yet, retrying in 100ms (attempt \(retryCount + 1)/5): \(fileURL)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.initializeAndPlay(retryCount: retryCount + 1)
                }
                return
            }
            debugPrint("⚠️ Cannot play video: file does not exist or is empty after \(retryCount) retries: \(fileURL)")
            return
        }

        debugPrint("🎬 Initializing and playing: \(fileURL)")

        // Check if already initialized with same URL
        let alreadyInitialized = currentMediaURL == fileURL && mediaListPlayer.mediaPlayer.media != nil

        if alreadyInitialized {
            // Already set up - just resume/play
            debugPrint("🎬 Already initialized, resuming playback")
            DispatchQueue.main.async { [weak self] in
                guard let self = self, !self.isBeingDeallocated else { return }
                let playerState = self.mediaListPlayer.mediaPlayer.state
                debugPrint("🎬 Player state: \(playerState.rawValue)")

                if playerState == .paused || playerState == .stopped {
                    self.mediaListPlayer.play()
                } else if playerState != .playing {
                    // For other states (opening, buffering, etc.), try play with media
                    if let media = self.media {
                        self.mediaListPlayer.play(media)
                    }
                }
                // If already playing, do nothing
            }
        } else {
            // Initialize the player
            self.initialize(url: fileURL)

            // Start playing immediately
            DispatchQueue.main.async { [weak self] in
                guard let self = self, !self.isBeingDeallocated else { return }

                if let media = self.media {
                    debugPrint("🎬 Starting playback with media")
                    self.mediaListPlayer.play(media)
                } else {
                    debugPrint("⚠️ No media to play")
                }
            }
        }
    }

    func resume() {
        guard !isBeingDeallocated else { return }
        if !mediaListPlayer.mediaPlayer.isPlaying {
            DispatchQueue.main.async { [weak self] in
                guard let self = self, !self.isBeingDeallocated else { return }
                debugPrint("▶️ Resuming playback")
                self.mediaListPlayer.play()
            }
        }
    }

    func pause() {
        guard !isBeingDeallocated else { return }
        if mediaListPlayer.mediaPlayer.canPause {
            DispatchQueue.main.async { [weak self] in
                guard let self = self, !self.isBeingDeallocated else { return }
                self.mediaListPlayer.pause()
            }
        }
    }

    func seek(time: VLCTime) {
        guard !isBeingDeallocated else { return }
        if mediaListPlayer.mediaPlayer.isSeekable {
            DispatchQueue.main.async { [weak self] in
                guard let self = self, !self.isBeingDeallocated else { return }
                self.mediaListPlayer.mediaPlayer.time = time
            }
        }
    }

    func jump(direction: VLCVideo.MediaControlDirection, time: Int32) {
        guard !isBeingDeallocated else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self, !self.isBeingDeallocated else { return }
            switch direction {
            case .forward:
                self.mediaListPlayer.mediaPlayer.jumpForward(time)
            case .backward:
                self.mediaListPlayer.mediaPlayer.jumpBackward(time)
            }
        }
    }

    /// Clean up the media player to prevent callbacks on deallocated objects.
    public static func dismantleUIView(_ uiView: VLCMediaListPlayerUIView, coordinator: VLCVideoView.Coordinator) {
        // Mark as being deallocated first
        uiView.isBeingDeallocated = true

        // Clear delegate immediately to prevent callbacks
        uiView.mediaListPlayer.mediaPlayer.delegate = nil
        uiView.delegate = nil
        // Then do cleanup
        DispatchQueue.main.async {
            uiView.mediaListPlayer.mediaPlayer.drawable = nil
            uiView.mediaListPlayer.mediaPlayer.stop()
            uiView.mediaListPlayer.stop()
            uiView.mediaListPlayer.mediaPlayer.media = nil
            uiView.mediaListPlayer.rootMedia = nil
            uiView.media = nil
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        debugPrint("🧹 VLCMediaListPlayerUIView deinit")
        // Don't call resetPlayer here - it's handled in dismantleUIView
        // Just mark as deallocated
        isBeingDeallocated = true
    }

    func setDelegate(_ delegate: VLCMediaPlayerDelegate) {
        guard !isBeingDeallocated else { return }
        self.delegate = delegate
        mediaListPlayer.mediaPlayer.delegate = delegate
    }
}
