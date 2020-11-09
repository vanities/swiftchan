//
//  VLCPlayerUIView.swift
//  swiftchan
//
//  Created by vanities on 11/6/20.
//

import MobileVLCKit
import Cache
import AVKit

class VLCPlayerUIView: UIView, VLCMediaPlayerDelegate {
    let url: URL
    var preview: Bool = false
    var mediaPlayer = VLCMediaPlayer()

    init(frame: CGRect, url: URL, preview: Bool) {
        self.url = url
        self.preview = preview
        super.init(frame: frame)

        CacheManager.shared.getFileWith(stringUrl: self.url.absoluteString) { result in

            switch result {
            case .success(let url):
                // do some magic with path to saved video
                self.setMediaPlayer(cacheUrl: url)

                break
            case .failure(let error):
                // handle errror
                print(error, " failure in the Cache of video")
                break
            }
        }
    }

    private func setMediaPlayer(cacheUrl: URL) {
        DispatchQueue.main.async {
            self.mediaPlayer.media = VLCMedia(url: cacheUrl)
            self.mediaPlayer.delegate = self
            self.mediaPlayer.drawable = self
            if !self.preview {
                self.mediaPlayer.play()
            }
        }
        #if DEBUG
        //self.mediaPlayer.pause()
        #endif
    }

    public func pause() {
        if self.mediaPlayer.canPause {
            self.mediaPlayer.pause()
        }
    }

    public func play() {
        if !self.mediaPlayer.isPlaying && self.mediaPlayer.willPlay {
            self.mediaPlayer.play()
        }
    }

    public func getLastSnapshot() -> UIImage {
        return self.mediaPlayer.lastSnapshot
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }
}
