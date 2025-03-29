//
//  VLCVideoView.swift
//  swiftchan
//
//  Created by vanities on 11/6/20.
//

import SwiftUI
import MobileVLCKit

struct VLCVideoView: UIViewRepresentable {
    @Environment(VLCVideoViewModel.self) var vlcVideoViewModel: VLCVideoViewModel

    func makeUIView(context: UIViewRepresentableContext<VLCVideoView>) -> VLCMediaListPlayerUIView {
        let view = VLCMediaListPlayerUIView(
            url: vlcVideoViewModel.video.url,
            frame: .zero
        )
        view.mediaListPlayer.mediaPlayer.delegate = context.coordinator
        return view
    }

    func updateUIView(
        _ uiView: VLCMediaListPlayerUIView,
        context: UIViewRepresentableContext<VLCVideoView>
    ) {
        // debugPrint("state change \(vlcVideoViewModel.vlcVideo.mediaControlState)")
        switch vlcVideoViewModel.video.mediaControlState {
        case .initialize:
            return
        case .play:
            uiView.initializeAndPlay()
        case .resume:
            uiView.resume()
        case .pause:
            uiView.pause()
        case .seek(let time):
            uiView.seek(time: time)
        case .jump(let direction, let time):
            uiView.jump(direction: direction, time: time)
        }
    }

    public static func dismantleUIView(_ uiView: VLCMediaListPlayerUIView, coordinator: VLCVideoView.Coordinator) {
        DispatchQueue.main.async {
            // Detach delegate and clear drawable to avoid callbacks on deallocated objects
            uiView.mediaListPlayer.mediaPlayer.delegate = nil
            uiView.mediaListPlayer.mediaPlayer.drawable = nil
            // Stop and clear the media to ensure proper cleanup
            uiView.mediaListPlayer.stop()
            uiView.mediaListPlayer.rootMedia = nil
        }
    }

    // MARK: Coordinator
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject,
                       UIGestureRecognizerDelegate,
                       VLCMediaPlayerDelegate {
        var parent: VLCVideoView

        init(_ parent: VLCVideoView) {
            self.parent = parent
        }

        func mediaPlayerTimeChanged(_ aNotification: Notification) {
            if let player = aNotification.object as? VLCMediaPlayer,
               let remainingTime = player.remainingTime,
               let media = player.media {
                parent.vlcVideoViewModel.updateTime(
                    current: player.time,
                    remaining: remainingTime,
                    total: VLCTime(
                        int: parent.vlcVideoViewModel.video.currentTime.intValue +
                        abs(parent.vlcVideoViewModel.video.remainingTime.intValue )
                    )
                )
                parent.vlcVideoViewModel.setMediaState(media.state)
                /*
                 debugPrint(
                """
                updating webm time \
                \(self.parent.vlcVideoViewModel.vlcVideo.currentTime) \
                \(self.parent.vlcVideoViewModel.vlcVideo.remainingTime) \
                \(self.parent.vlcVideoViewModel.vlcVideo.totalTime)
                """
                )
                 */
            }
        }

        func mediaPlayerStateChanged(_ aNotification: Notification) {
            if let player = aNotification.object as? VLCMediaPlayer {
                self.parent.vlcVideoViewModel.setMediaPlayerState(player.state)
                /*
                switch parent.vlcVideoViewModel.vlcVideo.mediaPlayerState {
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
        let url = URL(string: "google.com")!
        return ZStack {
            VLCVideoView()
                .environment(VLCVideoViewModel(url: url))
        }
    }
}
#endif
