//
//  VLCPlayerUIView.swift
//  swiftchan
//
//  Created by vanities on 11/6/20.
//

import SwiftUI
import AVKit

import MobileVLCKit

class VLCPlayerUIView: UIView, VLCMediaPlayerDelegate {
    let player: VLCMediaPlayer

    private let url: URL
    private let autoPlay: Bool

    weak var delegate: VLCPlayerUIViewDelegate?

    init(frame: CGRect,
         player: VLCMediaPlayer,
         url: URL,
         autoPlay: Bool) {
        self.player = player
        self.url = url
        self.autoPlay = autoPlay

        super.init(frame: frame)

        CacheManager.shared.getFileWith(stringUrl: self.url.absoluteString) { result in
            switch result {
            case .success(let url):
                self.setMediaPlayer(cacheUrl: url)
                break
            case .failure(let error):
                print(error, " failure in the Cache of video")
                break
            }
        }
    }

    func mediaPlayerSnapshot(_ aNotification: Notification!) {
        self.delegate?.onSnapshot(snapshot: self.player.lastSnapshot)
    }

    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        if let time = self.player.time {
            self.delegate?.onPlayerTimeChange(time: time)
        }
    }

    func mediaPlayerStateChanged(_ aNotification: Notification!) {
        self.delegate?.onStateChange(state: self.player.state)
    }

    func setMediaPlayer(cacheUrl: URL) {
        DispatchQueue.main.async {
            let media = VLCMedia(url: cacheUrl)
            self.player.media = media
            self.player.delegate = self
            self.player.drawable = self

            if self.autoPlay {
                self.player.play()
            }
        }
        #if DEBUG
        //self.mediaPlayer.pause()
        #endif
    }

    public func pause() {
        DispatchQueue.main.async {
            if self.player.canPause {
                self.player.pause()
                print("paused", self.url)
            }
        }
    }

    public func play() {
        DispatchQueue.main.async {
            if !self.player.isPlaying {
                self.player.play()
                print("played", self.url)
            }
        }
    }

    public func restart() {
        DispatchQueue.main.async {
            self.player.position = 0
            self.player.play()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }
}

protocol VLCPlayerUIViewDelegate: class {
    func onPlayerTimeChange(time: VLCTime)
    func onSnapshot(snapshot: UIImage)
    func onStateChange(state: VLCMediaPlayerState)
}

extension VLCMediaPlayer {
    public func restart() {
        DispatchQueue.main.async {
            let media = self.media
            self.media = media
            self.play()
        }
    }
}
