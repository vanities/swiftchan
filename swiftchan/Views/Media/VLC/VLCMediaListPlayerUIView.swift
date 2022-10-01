//
//  VLCMediaListPlayerUIView.swift
//  swiftchan
//
//  Created by Adam Mischke on 11/7/21.
//

import Foundation
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
    let mediaListPlayer = VLCMediaListPlayer()
    var media: VLCMedia?
    private var buffering = false

    init(url: URL, frame: CGRect) {
        self.url = url
        super.init(frame: frame)
    }

    func initialize(url: URL) {
        media = VLCMedia(url: url)
        if let media = self.media {
            media.addOption("-vv")
            // media.addOption("—network-caching=10000")
        }
        mediaListPlayer.rootMedia = self.media
        mediaListPlayer.mediaPlayer.media = self.media
        mediaListPlayer.mediaPlayer.drawable = self
        mediaListPlayer.repeatMode = .repeatCurrentItem
#if DEBUG
        mediaListPlayer.mediaPlayer.audio?.isMuted = true
#endif
    }

    func initializeAndPlay() {
        printState(mediaPlayerState: mediaListPlayer.mediaPlayer.state)
        if mediaListPlayer.mediaPlayer.state == .buffering {
            return
        }

        self.initialize(url: _url)

        guard let media = self.media else { return }

        if !mediaListPlayer.mediaPlayer.isPlaying {
            debugPrint("will play webm \(_url)")
            DispatchQueue.main.async { [weak self] in
                self?.mediaListPlayer.play(media)
                debugPrint("playing \(String(describing: self?._url))")
            }
        } else {
            debugPrint("will not play webm \(_url)")
        }
    }

    func resume() {
        if !mediaListPlayer.mediaPlayer.isPlaying {
            debugPrint("will play webm \(_url)")
            DispatchQueue.main.async { [weak self] in
                self?.mediaListPlayer.play()
                debugPrint("playing \(String(describing: self?._url))")
            }
        } else {
            debugPrint("will not play webm \(_url)")
        }
    }

    func pause() {
        if mediaListPlayer.mediaPlayer.canPause {
            debugPrint("will pause webm \(_url)")
            DispatchQueue.main.async { [weak self] in
                self?.mediaListPlayer.pause()
            }
        }
    }

    func seek(time: VLCTime) {
        if mediaListPlayer.mediaPlayer.isSeekable {
            debugPrint("will seek webm \(_url)")
            DispatchQueue.main.async { [weak self] in
                self?.mediaListPlayer.mediaPlayer.time = time
            }
        }
    }

    func jump(direction: VLCVideo.MediaControlDirection, time: Int32) {
        debugPrint("will jump webm \(_url)")
        DispatchQueue.main.async { [weak self] in
            switch direction {
            case .forward:
                self?.mediaListPlayer.mediaPlayer.jumpForward(time)
            case .backward:
                self?.mediaListPlayer.mediaPlayer.jumpBackward(time)
            }
        }
    }

    func printState(mediaPlayerState: VLCMediaPlayerState) {
        switch mediaPlayerState {
        case .esAdded:
            debugPrint("added webm \(_url)")
        case .playing:
            debugPrint("playing webm \(_url)")
        case .buffering:
            debugPrint("buffering webm \(_url)")
        case .ended:
            debugPrint("ended webm \(_url)")
        case .opening:
            debugPrint("opening webm \(_url)")
        case .paused:
            debugPrint("paused webm \(_url)")
        case .error:
            debugPrint("error webm \(_url)")
        case .stopped:
            debugPrint("stopped webm \(_url)")
        @unknown default:
            debugPrint("unknown state webm \(_url)")
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }
}
