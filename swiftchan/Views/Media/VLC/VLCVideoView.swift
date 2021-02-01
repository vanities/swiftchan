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
    @EnvironmentObject var video: VLCVideo
    @State var media: VLCMedia?

    func makeUIView(context: Context) -> UIView {
        let uiView = UIView()

        #if DEBUG
        self.setMediaPlayer(context: context)
        // self.setMediaPlayer(context: context, cacheUrl: url)
        #else
        self.setMediaPlayer(context: context)
        #endif

        self.playerList.mediaPlayer.drawable = uiView
        self.playerList.repeatMode = .repeatCurrentItem

        return uiView
    }

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<VLCVideoView>) {
        let playerList = context.coordinator.parent.playerList
        switch self.video.mediaState {
        case .play:
            if let player = playerList.mediaPlayer,
               !player.isPlaying,
               let media = self.media {
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
        }

    }

    public static func dismantleUIView(_ uiView: UIView, coordinator: VLCVideoView.Coordinator) {
        coordinator.parent.playerList.stop()
        coordinator.parent.playerList.rootMedia = nil
    }

    // MARK: Private
    private func setMediaPlayer(context: VLCVideoView.Context) {
        DispatchQueue.main.async {
            if let cacheUrl = self.video.cachedUrl {
                self.media = VLCMedia(url: cacheUrl)
            } else if let url = self.video.url {
                self.media = VLCMedia(url: url)
            }
            self.playerList.rootMedia = self.media
        }
        #if DEBUG
        // self.playerList.mediaPlayer.audio.isMuted = true
        #endif
    }

    // MARK: Coordinator
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, VLCMediaPlayerDelegate, VLCMediaDelegate {
        var parent: VLCVideoView

        init(_ parent: VLCVideoView) {
            self.parent = parent
        }

        // MARK: Player Delegate
        func mediaPlayerTimeChanged(_ aNotification: Notification!) {
            if let player = self.parent.playerList.mediaPlayer {
                self.parent.video.currentTime = player.time
                self.parent.video.remainingTime = player.remainingTime
                self.parent.video.totalTime = VLCTime(int: self.parent.video.currentTime.intValue + abs(self.parent.video.remainingTime.intValue))
                // print("time", self.parent.currentTime, self.parent.remainingTime, self.parent.totalTime)
            }
        }

        func mediaPlayerStateChanged(_ aNotification: Notification!) {
            if let player = self.parent.playerList.mediaPlayer {
                self.parent.video.state = player.state
            }
        }
    }
}

struct VlcPlayerDemo_Previews: PreviewProvider {
    static var previews: some View {
        return ZStack {
            VLCVideoView()
                .environmentObject(VLCVideo())
        }
    }
}
