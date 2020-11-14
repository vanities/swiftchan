//
//  VLCVideoView.swift
//  swiftchan
//
//  Created by vanities on 11/6/20.
//

import AVFoundation
import SwiftUI
import MobileVLCKit

struct VLCVideoView: UIViewRepresentable {
    let player: VLCMediaPlayer = VLCMediaPlayer()
    let url: URL
    let autoPlay: Bool
    let mediaState: MediaState

    @Binding private(set) var state: VLCMediaPlayerState
    @Binding private(set) var currentTime: VLCTime
    @Binding var remainingTime: VLCTime
    @Binding private(set) var totalTime: VLCTime

    func makeUIView(context: Context) -> UIView {
        let uiView = UIView()

        #if DEBUG
            self.setMediaPlayer(cacheUrl: url, context: context)
        #else
            CacheManager.shared.getFileWith(stringUrl: self.url.absoluteString) { result in
                switch result {
                case .success(let url):
                    self.setMediaPlayer(cacheUrl: url, context: context)
                    break
                case .failure(let error):
                    print(error, " failure in the Cache of video")
                    break
                }
            }
        #endif

        self.player.drawable = uiView
        self.player.delegate = context.coordinator

        return uiView
    }

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<VLCVideoView>) {
        switch mediaState {
        case .play:
            DispatchQueue.main.async {
                context.coordinator.parent.player.play()
            }
        case .pause:
            DispatchQueue.main.async {
                context.coordinator.parent.player.pause()
            }
        case .seek(let time):
            DispatchQueue.main.async {
                print("setting time to", Float(time.intValue))
                context.coordinator.parent.player.time = time
            }
        }
    }

    public static func dismantleUIView(_ uiView: UIView, coordinator: VLCVideoView.Coordinator) {
        coordinator.parent.player.stop()
        coordinator.parent.player.media = nil
    }

    // MARK: Private
    private func setMediaPlayer(cacheUrl: URL, context: VLCVideoView.Context) {
        DispatchQueue.main.async {
            let media = VLCMedia(url: cacheUrl)
            self.player.media = media
            self.player.media.delegate = context.coordinator

            if self.autoPlay {
                self.player.play()
            }
        }
        #if DEBUG
        //self.mediaPlayer.pause()
        #endif
    }

    // MARK: Coordinator
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, VLCMediaPlayerDelegate, VLCMediaDelegate, VLCMediaThumbnailerDelegate {

        var parent: VLCVideoView

        init(_ parent: VLCVideoView) {
            self.parent = parent
        }

        // MARK: Player Delegate
        func mediaPlayerTimeChanged(_ aNotification: Notification!) {
            self.parent.currentTime = self.parent.player.time
            self.parent.remainingTime = self.parent.player.remainingTime
            self.parent.totalTime = VLCTime(int: self.parent.player.time.intValue + abs(self.parent.player.remainingTime.intValue))
            //print("time", self.parent.currentTime, self.parent.remainingTime, self.parent.totalTime)
        }

        func mediaPlayerStateChanged(_ aNotification: Notification!) {
            self.parent.state = self.parent.player.state
        }

        // MARK: Thumbnailer Delegate
        func mediaThumbnailerDidTimeOut(_ mediaThumbnailer: VLCMediaThumbnailer!) {
            return
        }

        func mediaThumbnailer(_ mediaThumbnailer: VLCMediaThumbnailer!, didFinishThumbnail thumbnail: CGImage!) {
            return
        }
    }
}

struct VlcPlayerDemo_Previews: PreviewProvider {
    static var previews: some View {
        return ZStack {
            VLCVideoView(url: URLExamples.webm,
                         autoPlay: true,
                         mediaState: .play,
                         state: .constant(.playing),
                         currentTime: .constant(.init(int: 0)),
                         remainingTime: .constant(.init(int: 0)),
                         totalTime: .constant(.init(int: 0))
            )
        }
    }
}
