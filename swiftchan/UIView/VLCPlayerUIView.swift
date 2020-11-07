//
//  VLCPlayerUIView.swift
//  swiftchan
//
//  Created by vanities on 11/6/20.
//

import MobileVLCKit
import Cache

class VLCPlayerUIView: UIView, VLCMediaPlayerDelegate, ObservableObject {
    let url: URL
    var preview: Bool = false
    @Published var mediaPlayer = VLCMediaPlayer()
    //@Published var time: VLCTime = .init(int: 0)
    
    init(frame: CGRect, url: URL, preview: Bool) {
        self.url = url
        self.preview = preview
        super.init(frame: frame)

        CacheService.shared.getOrSet(key: self.url) { [weak self] complete in
            self?.setMediaPlayer(cacheUrl: complete)
        }
    }
    
    
    private func setMediaPlayer(cacheUrl: URL) {
        self.mediaPlayer.media = VLCMedia(url: cacheUrl)
        self.mediaPlayer.delegate = self
        self.mediaPlayer.drawable = self
        if !self.preview {
            DispatchQueue.main.async {
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
