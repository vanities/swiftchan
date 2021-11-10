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

    init(url: URL, frame: CGRect) {
        self.url = url
        super.init(frame: frame)
        self.url = getUrl(url: url)
        media = VLCMedia(url: url)
        if let media = media {
            media.addOption("-vv")
            media.addOption("—network-caching=10000")
        }
        mediaListPlayer.rootMedia = media
        mediaListPlayer.mediaPlayer.media = media
        mediaListPlayer.mediaPlayer.drawable = self
        mediaListPlayer.mediaPlayer.delegate = self
        mediaListPlayer.repeatMode = .repeatCurrentItem
#if DEBUG
        mediaListPlayer.mediaPlayer.audio.isMuted = true
#endif
    }

    func play() {
        //debugPrint("trying to play webm \(url)")
        printState(mediaPlayerState: mediaListPlayer.mediaPlayer.state)
        if !mediaListPlayer.mediaPlayer.isPlaying {
           //mediaListPlayer.mediaPlayer.willPlay {
            debugPrint("will play webm \(url)")
            DispatchQueue.main.async { [weak self] in
                self?.mediaListPlayer.play(self?.media)
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
            debugPrint("added webm")
        case .playing:
            debugPrint("playing webm")
        case .buffering:
            debugPrint("buffering webm")
        case .ended:
            debugPrint("ended webm")
        case .opening:
            debugPrint("opening webm")
        case .paused:
            debugPrint("paused webm")
        case .error:
            debugPrint("error webm")
        case .stopped:
            debugPrint("stopped webm")
        @unknown default:
            debugPrint("unknown state webm")
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
