//
//  VLCContainerView.swift
//  swiftchan
//
//  Created on 11/8/20.
//

import SwiftUI
import MobileVLCKit
import ToastUI
import Kingfisher

struct VLCContainerView: View {
    var isSelected: Bool

    @State var vlcVideoViewModel: VLCVideoViewModel
    @State private var presentingPlayerControl: Bool = false
    @State private(set) var presentingjumpToast: VLCVideo.MediaControlDirection?
    @State private(set) var downloadProgress = Progress()
    @State private var downloadPercentage: Int = 0
    @Environment(ThreadViewModel.self) private var viewModel
    @Environment(AppState.self) private var appState

    init(
        url: URL,
        isSelected: Bool
    ) {
        self._vlcVideoViewModel = State(
            wrappedValue: VLCVideoViewModel(url: url)
        )
        self.isSelected = isSelected
    }
    var onSeekChanged: ((Bool) -> Void)?

    var body: some View {
        return ZStack {
            VLCVideoView()

            if !vlcVideoViewModel.video.downloadProgress.isFinished {
                VStack {
                    Text("Downloading")
                        .foregroundColor(.white)
                    Text("\(downloadPercentage)%")
                        .foregroundColor(.white)
                        .font(.title)
                }
            }
        }
        .playerControl(presenting: $presentingPlayerControl, onSeekChanged: onSeekChanged)
        .environment(vlcVideoViewModel)
        .onReceive(Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()) { _ in
            // Update download percentage without circular dependency
            downloadPercentage = Int(vlcVideoViewModel.video.downloadProgress.fractionCompleted * 100)
        }
        .onChange(of: vlcVideoViewModel.video.mediaControlState) {
            if vlcVideoViewModel.video.mediaControlState == .play {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                    withAnimation(.linear(duration: 0.2)) {
                        presentingPlayerControl = false
                    }
                }
            }
        }
        .onChange(of: isSelected) {
            if isSelected {
                // Always try to play when selected, even if still downloading
                if vlcVideoViewModel.video.downloadProgress.isFinished {
                    vlcVideoViewModel.play()
                } else {
                    // Will play automatically when download completes
                }
            } else if !isSelected {
                vlcVideoViewModel.pause()
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            vlcVideoViewModel.pause()
            appState.vlcPlayerControlModifier = nil
        }
        .task {
            do {
                try await vlcVideoViewModel.download()
                // Always play after download if selected
                if isSelected {
                    // Add small delay to ensure file is ready
                    try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                    debugPrint("🎬 Triggering play after download")

                    // Ensure we're on the main actor for UI updates
                    await MainActor.run {
                        vlcVideoViewModel.play()
                    }
                }
            } catch {
                debugPrint("Failed to download video: \(error)")
            }
        }
    }
}

extension VLCContainerView: Buildable {
    func onSeekChanged(_ callback: ((Bool) -> Void)?) -> Self {
        mutating(keyPath: \.onSeekChanged, value: callback)
    }
}

#if DEBUG
#Preview {
    return Group {
        VLCContainerView(
            url: URLExamples.webm,
            isSelected: false
        )
        .background(Color.black)
        .previewInterfaceOrientation(.portrait)

        VLCContainerView(
            url: URLExamples.webm,
            isSelected: true
        )
        .background(Color.black)
        .previewInterfaceOrientation(.portrait)
    }
}
#endif
