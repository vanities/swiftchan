
//
//  VLCMediaListPlayerUIView.swift
//  Updated for Safe Cleanup and Playback Retry
//

import UIKit
import MobileVLCKit

class VLCMediaListPlayerUIView: UIView, VLCMediaPlayerDelegate {
    private var _url: URL {
        let cacheURL = CacheManager.shared.cacheURL(url)
        guard CacheManager.shared.cacheHit(file: cacheURL) else {
            return url
        }
        return cacheURL
    }
    private var url: URL
    private weak var delegate: VLCMediaPlayerDelegate?
    let mediaListPlayer = VLCMediaListPlayer()
    var media: VLCMedia?
    private var currentMediaURL: URL?

    init(url: URL, frame: CGRect = .zero) {
        self.url = url
        super.init(frame: frame)
    }

    /// Initialize the media with options and setup the media player.
    func initialize(url: URL) {
        guard currentMediaURL != url || mediaListPlayer.mediaPlayer.media == nil else { return }
        resetPlayer()
        media = VLCMedia(url: url)
        if let media = media {
            media.addOption("-vv")
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
        let cleanup = {
            // Detach the delegate and drawable first to avoid callbacks on
            // a deallocated object. Then stop playback and clear the media.
            self.mediaListPlayer.mediaPlayer.delegate = nil
            self.mediaListPlayer.mediaPlayer.drawable = nil
            self.mediaListPlayer.mediaPlayer.stop()
            self.mediaListPlayer.stop()
            self.mediaListPlayer.mediaPlayer.media = nil
            self.mediaListPlayer.rootMedia = nil
            self.currentMediaURL = nil
        }

        if Thread.isMainThread {
            cleanup()
        } else {
            DispatchQueue.main.async(execute: cleanup)
        }
    }


    /// Start playback with a fallback retry if buffering.
    func initializeAndPlay() {
        let fileURL = _url
        let fileExists = FileManager.default.fileExists(atPath: fileURL.path)
        let fileSizeValid = (try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64 ?? 0) ?? 0 > 0

        guard fileExists, fileSizeValid else {
            debugPrint("⚠️ Cannot play video: file does not exist or is empty \(fileURL)")
            return
        }

        if mediaListPlayer.mediaPlayer.state == .buffering {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if !self.mediaListPlayer.mediaPlayer.isPlaying, let media = self.media {
                    self.mediaListPlayer.play(media)
                }
            }
            return
        }

        self.initialize(url: fileURL)

        if !mediaListPlayer.mediaPlayer.isPlaying {
            DispatchQueue.main.async { [weak self] in
                if let media = self?.media {
                    self?.mediaListPlayer.play(media)
                }
            }
        }
    }


    func resume() {
        if !mediaListPlayer.mediaPlayer.isPlaying {
            DispatchQueue.main.async { [weak self] in
                self?.mediaListPlayer.play()
            }
        }
    }

    func pause() {
        if mediaListPlayer.mediaPlayer.canPause {
            DispatchQueue.main.async { [weak self] in
                self?.mediaListPlayer.pause()
            }
        }
    }

    func seek(time: VLCTime) {
        if mediaListPlayer.mediaPlayer.isSeekable {
            DispatchQueue.main.async { [weak self] in
                self?.mediaListPlayer.mediaPlayer.time = time
            }
        }
    }

    func jump(direction: VLCVideo.MediaControlDirection, time: Int32) {
        DispatchQueue.main.async { [weak self] in
            switch direction {
            case .forward:
                self?.mediaListPlayer.mediaPlayer.jumpForward(time)
            case .backward:
                self?.mediaListPlayer.mediaPlayer.jumpBackward(time)
            }
        }
    }

    /// Clean up the media player to prevent callbacks on deallocated objects.
    public static func dismantleUIView(_ uiView: VLCMediaListPlayerUIView, coordinator: VLCVideoView.Coordinator) {
        DispatchQueue.main.async {
            uiView.resetPlayer()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        debugPrint("🧹 VLCMediaListPlayerUIView deinit")
        resetPlayer()
    }
    
    func setDelegate(_ delegate: VLCMediaPlayerDelegate) {
        self.delegate = delegate
        mediaListPlayer.mediaPlayer.delegate = delegate
    }
}
