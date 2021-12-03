//
//  VLCMediaListPlayerUIView.swift
//  swiftchan
//
//  Created by Adam Mischke on 11/7/21.
//

import Foundation
import MobileVLCKit

class VLCMediaListPlayerUIView: UIView, VLCMediaPlayerDelegate {
    private var url: URL
    let mediaListPlayer = VLCMediaListPlayer()
    var media: VLCMedia?

    var urlIsStreaming: Bool {
        self.url.host == "i.4cdn.org"
    }

    var urlIsLocal: Bool {
        self.url.host == nil
    }

    var cacheMiss: Bool {
        getUrl(url: url) == url
    }

    init(url: URL, frame: CGRect) {
        self.url = url
        super.init(frame: frame)
        self.initialize(url: url)
    }

    func initialize(url: URL) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            //self.url = self.getUrl(url: url)
            self.media = VLCMedia(url: url)
            if let media = self.media {
                media.addOption("-vv")
                //media.addOption("—network-caching=10000")
            }
            self.mediaListPlayer.rootMedia = self.media
            self.mediaListPlayer.mediaPlayer.media = self.media
            self.mediaListPlayer.mediaPlayer.drawable = self
            self.mediaListPlayer.repeatMode = .repeatCurrentItem
#if DEBUG
            self.mediaListPlayer.mediaPlayer.audio.isMuted = true
#endif
        }
    }

    func play() {
        printState(mediaPlayerState: mediaListPlayer.mediaPlayer.state)
        if mediaListPlayer.mediaPlayer.state == .buffering {
            return
        }
        /*a
        if urlIsStreaming, !mediaListPlayer.mediaPlayer.isPlaying, mediaListPlayer.mediaPlayer.state != .buffering {
            DispatchQueue.main.async { [weak self] in
                self?.mediaListPlayer.play(self?.media)
            }
            return
         }
         */
        // debugPrint("trying to play webm \(url)")
        //guard mediaListPlayer.mediaPlayer.state == .stopped else { return }

        if !mediaListPlayer.mediaPlayer.isPlaying {
            debugPrint("will play webm \(url)")
            DispatchQueue.main.async { [weak self] in
                self?.mediaListPlayer.play(self?.media)
                debugPrint("playing \(self?.url)")
            }
        } else {
            debugPrint("will not play webm \(url)")
        }
    }

    func pause() {
        if mediaListPlayer.mediaPlayer.canPause {
            debugPrint("will pause webm \(url)")
            DispatchQueue.main.async { [weak self] in
                self?.mediaListPlayer.pause()
            }
        }
    }

    func seek(time: VLCTime) {
        if mediaListPlayer.mediaPlayer.isSeekable {
            debugPrint("will seek webm \(url)")
            DispatchQueue.main.async { [weak self] in
                self?.mediaListPlayer.mediaPlayer?.time = time
            }
        }
    }

    func jump(direction: VLCVideo.MediaControlDirection, time: Int32) {
        debugPrint("will jump webm \(url)")
        DispatchQueue.main.async { [weak self] in
            switch direction {
            case .forward:
                self?.mediaListPlayer.mediaPlayer?.jumpForward(time)
            case .backward:
                self?.mediaListPlayer.mediaPlayer?.jumpBackward(time)
            }
        }
    }

    func printState(mediaPlayerState: VLCMediaPlayerState) {
        switch mediaPlayerState {
        case .esAdded:
            debugPrint("added webm \(url)")
        case .playing:
            debugPrint("playing webm \(url)")
        case .buffering:
            debugPrint("buffering webm \(url)")
        case .ended:
            debugPrint("ended webm \(url)")
        case .opening:
            debugPrint("opening webm \(url)")
        case .paused:
            debugPrint("paused webm \(url)")
        case .error:
            debugPrint("error webm \(url)")
        case .stopped:
            debugPrint("stopped webm \(url)")
        @unknown default:
            debugPrint("unknown state webm \(url)")
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    // MARK: Private
    private func getUrl(url: URL) -> URL {
        if let cacheUrl = CacheManager.shared.getCacheValue(url) {
            debugPrint("cache hit webm \(cacheUrl)")
            return cacheUrl
        } else {
            debugPrint("cache miss webm \(url)")
            return url
        }
    }
}

extension VLCMediaListPlayerUIView: StreamDelegate {

}
