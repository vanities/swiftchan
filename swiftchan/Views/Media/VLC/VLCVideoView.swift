//
//  VLCVideoView.swift
//  swiftchan
//
//  Created on 11/6/20.
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
        view.initialize(url: vlcVideoViewModel.video.url)
        view.setDelegate(context.coordinator)
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
        VLCMediaListPlayerUIView.dismantleUIView(uiView, coordinator: coordinator)
    }

    // MARK: Coordinator
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: vlcVideoViewModel)
    }

    class Coordinator: NSObject,
                       UIGestureRecognizerDelegate,
                       VLCMediaPlayerDelegate {
        private weak var viewModel: VLCVideoViewModel?

        init(viewModel: VLCVideoViewModel) {
            self.viewModel = viewModel
        }

        nonisolated func mediaPlayerTimeChanged(_ aNotification: Notification) {
            //print("🕒 Time changed")
            guard let player = aNotification.object as? VLCMediaPlayer else { return }

            Task { @MainActor in
                guard let viewModel = viewModel else { return }

                // These must be accessed on the main actor
                guard let remainingTime = player.remainingTime,
                      let media = player.media else { return }

                let currentTime = player.time
                let totalTime = VLCTime(int: currentTime.intValue + abs(remainingTime.intValue))
                let mediaState = media.state

                viewModel.updateTime(current: currentTime, remaining: remainingTime, total: totalTime)
                viewModel.setMediaState(mediaState)
            }

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

        nonisolated func mediaPlayerStateChanged(_ aNotification: Notification) {
            guard let player = aNotification.object as? VLCMediaPlayer else {
                print("Wrong object in notification")
                return }

            // Extract value(s) in nonisolated/task context
            let state = player.state
            print("Player state changed to: \(state.rawValue)")

            // Hop to MainActor only with safe data
            Task { @MainActor in
                self.viewModel?.setMediaPlayerState(state)
            }
        }

        @MainActor
        func handleStateChange(from player: VLCMediaPlayer) {
            self.viewModel?.setMediaPlayerState(player.state)
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
