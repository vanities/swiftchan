//
//  VLCMediaListPlayerUIView.swift
//  swiftchan
//
//  Created by Adam Mischke on 11/7/21.
//

import Foundation
import MobileVLCKit

protocol VLCMediaListPlayerUIViewDelegate: AnyObject {
    func mediaPlayerTimeChanged(view: VLCMediaListPlayerUIView)
    func mediaPlayerStateChanged(view: VLCMediaListPlayerUIView)
}

class VLCMediaListPlayerUIView: UIView {
    private let url: URL
    let mediaListPlayer = VLCMediaListPlayer()
    var media: VLCMedia?
    weak var delegate: VLCMediaListPlayerUIViewDelegate?

    init(url: URL, frame: CGRect) {
        self.url = url
        super.init(frame: frame)
        let urls = VLCVideoView.getUrl(url: url)
        media = VLCMedia(url: urls)
        mediaListPlayer.rootMedia = media
        mediaListPlayer.delegate = self
        mediaListPlayer.mediaPlayer.media = media
        mediaListPlayer.mediaPlayer.delegate = self
        mediaListPlayer.mediaPlayer.drawable = self
        mediaListPlayer.repeatMode = .repeatCurrentItem
#if DEBUG
        mediaListPlayer.mediaPlayer.audio.isMuted = true
#endif
    }

    func play() {
        debugPrint("trying to play webm \(url)")
        if !mediaListPlayer.mediaPlayer.isPlaying {
            if mediaListPlayer.mediaPlayer.willPlay {
                debugPrint("will play webm \(url)")
            } else {
                debugPrint("will not play webm \(url)")
            }
            DispatchQueue.main.async { [weak self] in
                self?.mediaListPlayer.play(self?.media)
            }
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

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }
}

extension VLCMediaListPlayerUIView: VLCMediaPlayerDelegate {
    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        delegate?.mediaPlayerTimeChanged(view: self)
    }
    func mediaPlayerStateChanged(_ aNotification: Notification!) {
        delegate?.mediaPlayerStateChanged(view: self)
    }
}
extension VLCMediaListPlayerUIView: VLCMediaListPlayerDelegate {
}
