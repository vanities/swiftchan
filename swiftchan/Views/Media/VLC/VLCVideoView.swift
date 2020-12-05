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
    let autoPlay: Bool
    @Binding private(set) var mediaState: MediaState

    @Binding private(set) var state: VLCMediaPlayerState
    @Binding private(set) var currentTime: VLCTime
    @Binding private(set) var remainingTime: VLCTime
    @Binding private(set) var totalTime: VLCTime

    @State var media: VLCMedia?

    func makeUIView(context: Context) -> UIView {
        let uiView = UIView()

        #if DEBUG
        self.setCachedMediaPlayer(context: context)
        //self.setMediaPlayer(context: context, cacheUrl: url)
        #else
        self.setCachedMediaPlayer(context: context)
        #endif

        self.playerList.mediaPlayer.drawable = uiView
        self.playerList.repeatMode = .repeatCurrentItem

        return uiView
    }

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<VLCVideoView>) {
        switch mediaState {
        case .play:
            if !context.coordinator.parent.playerList.mediaPlayer.isPlaying,
               let media = self.media {
                DispatchQueue.main.async {
                    if context.coordinator.parent.playerList.mediaPlayer.media == nil {
                        context.coordinator.parent.playerList.play(media)
                        context.coordinator.parent.playerList.mediaPlayer.delegate = context.coordinator
                    } else {
                        context.coordinator.parent.playerList.play()
                    }
                }
            }
        case .pause:
            if context.coordinator.parent.playerList.mediaPlayer.canPause {
                DispatchQueue.main.async {
                    context.coordinator.parent.playerList.pause()
                }
            }
        case .seek(let time):
            if context.coordinator.parent.playerList.mediaPlayer.isSeekable {
                DispatchQueue.main.async {
                    context.coordinator.parent.playerList.mediaPlayer?.time = time
                }
            }
        }

    }

    public static func dismantleUIView(_ uiView: UIView, coordinator: VLCVideoView.Coordinator) {
        coordinator.parent.playerList.stop()
        coordinator.parent.playerList.rootMedia = nil
    }

    // MARK: Private
    private func setMediaPlayer(context: VLCVideoView.Context, cacheUrl: URL) {
        DispatchQueue.main.async {
            self.media = VLCMedia(url: cacheUrl)
            self.playerList.rootMedia = self.media

            if self.autoPlay {
                self.playerList.mediaPlayer.delegate = context.coordinator
                self.playerList.play(self.media)
            }
        }
        #if DEBUG
        //self.playerList.mediaPlayer.audio.isMuted = true
        #endif
    }

    private func setCachedMediaPlayer(context: VLCVideoView.Context) {
        CacheManager.shared.getFileWith(stringUrl: self.url.absoluteString) { result in
            switch result {
            case .success(let url):
                self.setMediaPlayer(context: context, cacheUrl: url)
            case .failure(let error):
                print(error, " failure in the Cache of video")
            }
        }
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
            self.parent.currentTime = self.parent.playerList.mediaPlayer.time
            self.parent.remainingTime = self.parent.playerList.mediaPlayer.remainingTime
            self.parent.totalTime = VLCTime(int: self.parent.currentTime.intValue + abs(self.parent.remainingTime.intValue))
            //print("time", self.parent.currentTime, self.parent.remainingTime, self.parent.totalTime)
        }

        func mediaPlayerStateChanged(_ aNotification: Notification!) {
            self.parent.state = self.parent.playerList.mediaPlayer.state
        }
    }
}

struct VlcPlayerDemo_Previews: PreviewProvider {
    static var previews: some View {
        return ZStack {
            VLCVideoView(url: URLExamples.webm,
                         autoPlay: true,
                         mediaState: .constant(.play),
                         state: .constant(.playing),
                         currentTime: .constant(.init(int: 0)),
                         remainingTime: .constant(.init(int: 0)),
                         totalTime: .constant(.init(int: 0))
            )
        }
    }
}
