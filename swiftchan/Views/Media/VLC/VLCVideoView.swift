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
    @EnvironmentObject var vlcVideoViewModel: VLCVideoViewModel
    @State var media: VLCMedia?

    func makeUIView(context: Context) -> UIView {
        let uiView = UIView()

        self.setMediaPlayer(context: context)

        self.playerList.mediaPlayer.drawable = uiView
        self.playerList.repeatMode = .repeatCurrentItem

        return uiView
    }

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<VLCVideoView>) {
        let playerList = context.coordinator.parent.playerList
        if self.media == nil {
            self.setMediaPlayer(context: context)
        }

        switch vlcVideoViewModel.vlcVideo.mediaState {
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
            if let cacheUrl = vlcVideoViewModel.vlcVideo.cachedUrl {
                self.media = VLCMedia(url: cacheUrl)
                self.playerList.rootMedia = self.media
                context.coordinator.parent.playerList.rootMedia = self.media
            } else if let url = vlcVideoViewModel.vlcVideo.url {
                self.media = VLCMedia(url: url)
                self.playerList.rootMedia = self.media
                context.coordinator.parent.playerList.rootMedia = self.media
            }
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
            if let player = parent.playerList.mediaPlayer {
                parent.vlcVideoViewModel.vlcVideo.currentTime = player.time
                parent.vlcVideoViewModel.vlcVideo.remainingTime = player.remainingTime
                parent.vlcVideoViewModel.vlcVideo.totalTime = VLCTime(int: parent.vlcVideoViewModel.vlcVideo.currentTime.intValue + abs(parent.vlcVideoViewModel.vlcVideo.remainingTime.intValue))
                // print("time", self.parent.currentTime, self.parent.remainingTime, self.parent.totalTime)
            }
        }

        func mediaPlayerStateChanged(_ aNotification: Notification!) {
            if let player = parent.playerList.mediaPlayer {
                parent.vlcVideoViewModel.vlcVideo.state = player.state
            }
        }
    }
}

struct VlcPlayerDemo_Previews: PreviewProvider {
    static var previews: some View {
        return ZStack {
            VLCVideoView()
                .environmentObject(VLCVideoViewModel())
        }
    }
}
