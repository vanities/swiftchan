//
//  VLCVideoView.swift
//  swiftchan
//
//  Created by vanities on 11/6/20.
//

import SwiftUI
import MobileVLCKit

struct VLCVideoView: UIViewRepresentable {
    let playerList: VLCMediaListPlayer = VLCMediaListPlayer()
    let url: URL
    @EnvironmentObject var vlcVideoViewModel: VLCVideoViewModel
    @State var media: VLCMedia?

    func makeUIView(context: Context) -> UIView {
        let uiView = UIView()

        setMediaPlayer(context: context)

        playerList.mediaPlayer.drawable = uiView
        playerList.repeatMode = .repeatCurrentItem

        return uiView
    }

    // swiftlint:disable all
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<VLCVideoView>) {
        let playerList = context.coordinator.parent.playerList
        if media == nil {
            setMediaPlayer(context: context)
        }

        switch vlcVideoViewModel.vlcVideo.mediaControlState {
        case .play:
            if let player = playerList.mediaPlayer,
               !player.isPlaying,
               let media = media {
                DispatchQueue.main.async {
                    if player.media == nil {
                        playerList.play(media)
                        player.delegate = context.coordinator
                    } else {
                        playerList.play()
                    }
                }
            }
        case .pause:
            if playerList.mediaPlayer.canPause {
                DispatchQueue.main.async {
                    playerList.pause()
                }
            }
        case .seek(let time):
            if playerList.mediaPlayer.isSeekable {
                DispatchQueue.main.async {
                    playerList.mediaPlayer?.time = time
                }
            }
        case .jump(let direction, let time):
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

    public static func dismantleUIView(_ uiView: UIView, coordinator: VLCVideoView.Coordinator) {
        coordinator.parent.playerList.stop()
        coordinator.parent.playerList.rootMedia = nil
    }

    // MARK: Private
    private func setMediaPlayer(context: VLCVideoView.Context) {
        DispatchQueue.main.async {
            if let cacheUrl = CacheManager.shared.getCacheValue(url) {
                media = VLCMedia(url: cacheUrl)
                playerList.rootMedia = media
                context.coordinator.parent.playerList.rootMedia = media
                playerList.play(media)
            } else {
                media = VLCMedia(url: url)
                playerList.rootMedia = media
                context.coordinator.parent.playerList.rootMedia = media
            }
        }
#if DEBUG
        self.playerList.mediaPlayer.audio.isMuted = true
#endif
    }

    // MARK: Coordinator
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

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
                parent.vlcVideoViewModel.vlcVideo.mediaPlayerState = player.state
            }
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
        }

    }
}

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
