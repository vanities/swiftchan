//
//  VLCVideoView.swift
//  swiftchan
//
//  Created by vanities on 11/6/20.
//

import SwiftUI
import MobileVLCKit

struct VLCVideoView: UIViewRepresentable {
    let url: URL
    @EnvironmentObject var vlcVideoViewModel: VLCVideoViewModel

    func makeUIView(context: UIViewRepresentableContext<VLCVideoView>) -> VLCMediaListPlayerUIView {
        let view = VLCMediaListPlayerUIView(url: url, frame: .zero)
        view.delegate = context.coordinator
        debugPrint(vlcVideoViewModel)
        vlcVideoViewModel.vlcVideo.currentTime = context.coordinator.parent.vlcVideoViewModel.vlcVideo.currentTime
        return view
    }

    // swiftlint:disable all
    func updateUIView(_ uiView: VLCMediaListPlayerUIView, context: UIViewRepresentableContext<VLCVideoView>) {
        debugPrint("state change \(vlcVideoViewModel.vlcVideo.mediaControlState)")
        switch vlcVideoViewModel.vlcVideo.mediaControlState {
        case .initialize:
            return
        case .play:
            uiView.play()
        case .pause:
            uiView.pause()
        case .seek(let time):
            uiView.seek(time: time)
        case .jump(let direction, let time):
            uiView.jump(direction: direction, time: time)
            vlcVideoViewModel.vlcVideo.mediaControlState = .play
        }
    }
    // swiftlint:enable all

    public static func dismantleUIView(_ uiView: VLCMediaListPlayerUIView, coordinator: VLCVideoView.Coordinator) {
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
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, VLCMediaListPlayerUIViewDelegate, UIGestureRecognizerDelegate {

        var parent: VLCVideoView
        var observer: Any?

        init(_ parent: VLCVideoView) {
            self.parent = parent
        }

        // MARK: Player Delegate
        func mediaPlayerTimeChanged(view: VLCMediaListPlayerUIView) {
            DispatchQueue.main.async { [weak self, unowned view] in
                guard let `self` = self else { return }
                if let player = view.mediaListPlayer.mediaPlayer {
                    self.parent.vlcVideoViewModel.vlcVideo.currentTime = player.time
                    self.parent.vlcVideoViewModel.vlcVideo.remainingTime = player.remainingTime
                    self.parent.vlcVideoViewModel.vlcVideo.totalTime = VLCTime(
                        int: self.parent.vlcVideoViewModel.vlcVideo.currentTime.intValue +
                        abs(self.parent.vlcVideoViewModel.vlcVideo.remainingTime.intValue )
                    )

                    self.parent.vlcVideoViewModel.vlcVideo.mediaState = player.media.state
                    debugPrint(
                    """
                    updating webm time \
                    \(self.parent.vlcVideoViewModel.vlcVideo.currentTime) \
                    \(self.parent.vlcVideoViewModel.vlcVideo.remainingTime) \
                    \(self.parent.vlcVideoViewModel.vlcVideo.totalTime)
                    """
                    )
                }
            }
        }

        func mediaPlayerStateChanged(view: VLCMediaListPlayerUIView) {
            if let player = view.mediaListPlayer.mediaPlayer {
                self.parent.vlcVideoViewModel.vlcVideo.mediaPlayerState = player.state
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
