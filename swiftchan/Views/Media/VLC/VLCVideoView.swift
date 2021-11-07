//
//  VLCVideoView.swift
//  swiftchan
//
//  Created by vanities on 11/6/20.
//

import SwiftUI
import MobileVLCKit

class PlayerUIView: UIView, VLCMediaPlayerDelegate, VLCMediaListPlayerDelegate {
    private let url: URL
    let mediaListPlayer = VLCMediaListPlayer()
    private let mediaPlayer = VLCMediaPlayer()
    var media: VLCMedia?

    init(url: URL, frame: CGRect) {
        self.url = url
        super.init(frame: frame)
        let urls = VLCVideoView.getUrl(url: url)
        media = VLCMedia(url: urls)
        mediaListPlayer.rootMedia = media
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

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }
}

struct VLCVideoView: UIViewRepresentable {
    let url: URL
    @EnvironmentObject var vlcVideoViewModel: VLCVideoViewModel

    func makeUIView(context: Context) -> PlayerUIView {
        let uiView = PlayerUIView(url: url, frame: .init(x: 150, y: 300, width: 300, height: 300))
        return uiView
    }

    // swiftlint:disable all
    func updateUIView(_ uiView: PlayerUIView, context: UIViewRepresentableContext<VLCVideoView>) {
        let playerList = uiView.mediaListPlayer
        guard let url = playerList.rootMedia?.url else {return}
        
        guard let player = playerList.mediaPlayer else { return }
        debugPrint("state change \(vlcVideoViewModel.vlcVideo.mediaControlState)")
        switch vlcVideoViewModel.vlcVideo.mediaControlState {
        case .initialize:
            return
        case .play:
            uiView.play()
        case .pause:
            if playerList.mediaPlayer.canPause {
                debugPrint("will pause webm \(url)")
                DispatchQueue.main.async {
                    playerList.pause()
                }
            }
        case .seek(let time):
            if playerList.mediaPlayer.isSeekable {
                debugPrint("will seek webm \(url)")
                DispatchQueue.main.async {
                    playerList.mediaPlayer?.time = time
                }
            }
        case .jump(let direction, let time):
            debugPrint("will jump webm \(url)")
            DispatchQueue.main.async {
                switch direction {
                case .forward:
                    playerList.mediaPlayer?.jumpForward(time)
                    vlcVideoViewModel.vlcVideo.mediaControlState = .play
                case .backward:
                    playerList.mediaPlayer?.jumpBackward(time)
                    vlcVideoViewModel.vlcVideo.mediaControlState = .play
                }
            }
        }
    }
    // swiftlint:enable all

    public static func dismantleUIView(_ uiView: PlayerUIView, coordinator: VLCVideoView.Coordinator) {
        uiView.mediaListPlayer.stop()
        uiView.mediaListPlayer.rootMedia = nil
    }

    // MARK: Private
    static func getUrl(url: URL) -> URL {
        if let cacheUrl = CacheManager.shared.getCacheValue(url) {
            debugPrint("cache hit webm \(cacheUrl)")
            return cacheUrl
        } else {
            debugPrint("cache miss webm \(url)")
            return url
        }
    }

    // MARK: Coordinator
    /*
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
     */

    /*
    class Coordinator: NSObject, VLCMediaPlayerDelegate, VLCMediaDelegate, UIGestureRecognizerDelegate {
        var parent: VLCVideoView

        init(_ parent: VLCVideoView) {
            self.parent = parent
        }

        // MARK: Player Delegate
        func mediaPlayerTimeChanged(_ aNotification: Notification!) {
            if let player = parent.playerList.mediaPlayer {
                parent.vlcVideoViewModel.vlcVideo.currentTime = player.time
                parent.vlcVideoViewModel.vlcVideo.remainingTime = player.remainingTime
                parent.vlcVideoViewModel.vlcVideo.totalTime = VLCTime(int: parent.vlcVideoViewModel.vlcVideo.currentTime.intValue + abs(parent.vlcVideoViewModel.vlcVideo.remainingTime.intValue))

                parent.vlcVideoViewModel.vlcVideo.mediaState = player.media.state
                // print("time", self.parent.currentTime, self.parent.remainingTime, self.parent.totalTime)
            }
        }

        func mediaPlayerStateChanged(_ aNotification: Notification!) {
            if let player = parent.playerList.mediaPlayer {
                /*
                 switch player.state {
                 case .esAdded:
                 debugPrint("added webm \(parent.url)")
                 case .playing:
                 debugPrint("playing webm \(parent.url)")
                 case .buffering:
                 debugPrint("buffering webm \(parent.url)")
                 case .ended:
                 debugPrint("ended webm \(parent.url)")
                 case .opening:
                 debugPrint("opening webm \(parent.url)")
                 case .paused:
                 debugPrint("paused webm \(parent.url)")
                 case .error:
                 debugPrint("error webm \(parent.url)")
                 case .stopped:
                 debugPrint("stopped webm \(parent.url)")
                 @unknown default:
                 debugPrint("unknown state webm \(parent.url)")
                 }
                 */
                parent.vlcVideoViewModel.vlcVideo.mediaPlayerState = player.state
            }
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
     

    }
     */
}

/*
 #if DEBUG
 struct VlcPlayerDemo_Previews: PreviewProvider {
 static var previews: some View {
 return ZStack {
 VLCVideoView(url: URLExamples.webm)
 .environmentObject(VLCVideoViewModel())
 }
 }
 }
 #endif
 
 */
