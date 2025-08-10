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

        // Connect the view to the view model for direct commands
        vlcVideoViewModel.vlcUIView = view
        debugPrint("🔗 Connected UIView to ViewModel")

        return view
    }

    func updateUIView(
        _ uiView: VLCMediaListPlayerUIView,
        context: UIViewRepresentableContext<VLCVideoView>
    ) {
        @Bindable var viewModel = vlcVideoViewModel
        let currentState = viewModel.video.mediaControlState
        debugPrint("🎮 updateUIView called with state: \(currentState)")

        switch currentState {
        case .initialize:
            return
        case .play:
            debugPrint("🎮 Calling initializeAndPlay")
            uiView.initializeAndPlay()
            // Reset to initialize to prevent repeated calls
            DispatchQueue.main.async {
                viewModel.setMediaControlState(.initialize)
            }
        case .resume:
            debugPrint("🎮 Calling resume")
            uiView.resume()
            DispatchQueue.main.async {
                viewModel.setMediaControlState(.initialize)
            }
        case .pause:
            debugPrint("🎮 Calling pause")
            uiView.pause()
            DispatchQueue.main.async {
                viewModel.setMediaControlState(.initialize)
            }
        case .seek(let time):
            debugPrint("🎮 Calling seek")
            uiView.seek(time: time)
            DispatchQueue.main.async {
                viewModel.setMediaControlState(.initialize)
            }
        case .jump(let direction, let time):
            debugPrint("🎮 Calling jump")
            uiView.jump(direction: direction, time: time)
            DispatchQueue.main.async {
                viewModel.setMediaControlState(.initialize)
            }
        }
    }

    public static func dismantleUIView(_ uiView: VLCMediaListPlayerUIView, coordinator: VLCVideoView.Coordinator) {
        // Clean up the reference
        coordinator.viewModel?.vlcUIView = nil
        debugPrint("🔗 Disconnected UIView from ViewModel")
        VLCMediaListPlayerUIView.dismantleUIView(uiView, coordinator: coordinator)
    }

    // MARK: Coordinator
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: vlcVideoViewModel)
    }

    class Coordinator: NSObject,
                       UIGestureRecognizerDelegate,
                       VLCMediaPlayerDelegate {
        weak var viewModel: VLCVideoViewModel?

        init(viewModel: VLCVideoViewModel) {
            self.viewModel = viewModel
        }

        nonisolated func mediaPlayerTimeChanged(_ aNotification: Notification) {
            guard let player = aNotification.object as? VLCMediaPlayer else { return }

            // Capture values in nonisolated context
            let currentTime = player.time
            let remainingTime = player.remainingTime
            let mediaState = player.media?.state

            guard let remainingTime = remainingTime,
                  let mediaState = mediaState else {
                debugPrint("⚠️ Time changed but missing data")
                return
            }

            let totalTime = VLCTime(int: currentTime.intValue + abs(remainingTime.intValue))

            // Debug every few seconds to see if callbacks are working
            if currentTime.intValue % 3000 == 0 && currentTime.intValue > 0 {
                debugPrint("🕒 Time callback working: \(currentTime.description)")
            }

            // Force immediate main thread execution
            DispatchQueue.main.async { [weak viewModel] in
                guard let viewModel = viewModel else { return }
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
                return
            }

            // Extract value in nonisolated context
            let state = player.state
            let stateDescription = stateToString(state)
            print("🎮 Player state changed to: \(state.rawValue) (\(stateDescription))")

            // Force immediate main thread execution
            DispatchQueue.main.async { [weak viewModel] in
                viewModel?.setMediaPlayerState(state)
            }
        }

        @MainActor
        func handleStateChange(from player: VLCMediaPlayer) {
            self.viewModel?.setMediaPlayerState(player.state)
        }

        func stateToString(_ state: VLCMediaPlayerState) -> String {
            switch state {
            case .opening: return "opening"
            case .buffering: return "buffering"
            case .playing: return "playing"
            case .paused: return "paused"
            case .stopped: return "stopped"
            case .ended: return "ended"
            case .error: return "error"
            @unknown default: return "unknown"
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
