//
//  VLCContainerView.swift
//  swiftchan
//
//  Created by vanities on 11/8/20.
//

import SwiftUI
import MobileVLCKit
import ToastUI
import Kingfisher

struct VLCContainerView: View {
    var isSelected: Bool

    @StateObject var vlcVideoViewModel: VLCVideoViewModel
    @State private var presentingPlayerControl: Bool = false
    @State private(set) var presentingjumpToast: VLCVideo.MediaControlDirection?
    @State private(set) var downloadProgress = Progress()
    @EnvironmentObject var threadViewModel: ThreadView.ViewModel
    @EnvironmentObject var appState: AppState

    init(
        url: URL,
        isSelected: Bool
    ) {
        self._vlcVideoViewModel = StateObject(
            wrappedValue: VLCVideoViewModel(url: url)
        )
        self.isSelected = isSelected
    }
    var onSeekChanged: ((Bool) -> Void)?

    var body: some View {
        return ZStack {
            VLCVideoView()

            if !vlcVideoViewModel.video.downloadProgress.isFinished {
                ProgressView("Downloading")
                /*
                ProgressView(vlcVideoViewModel.video.downloadProgress)
                    .frame(width: 50, height: 50)
                    .progressViewStyle(GaugeProgressStyle())
                 */
            }
            if vlcVideoViewModel.video.downloadProgress.isFinished && vlcVideoViewModel.video.mediaState == .buffering {
                ProgressView("Buffering")
            }
        }
        .playerControl(presenting: $presentingPlayerControl)
        .environmentObject(vlcVideoViewModel)
        .onChange(of: vlcVideoViewModel.video.mediaControlState) { state in
            if state == .play {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                    withAnimation(.linear(duration: 0.2)) {
                        presentingPlayerControl = false
                    }
                }
            }
        }
        .onChange(of: vlcVideoViewModel.video.downloadProgress.isFinished) { value in
            if value && isSelected {
                DispatchQueue.main.async {
                    vlcVideoViewModel.play()
                }
            }
        }
        .onChange(of: isSelected) { value in
            if value && vlcVideoViewModel.video.downloadProgress.isFinished {
                DispatchQueue.main.async {
                    vlcVideoViewModel.play()
                }
            } else {
                DispatchQueue.main.async {
                    vlcVideoViewModel.pause()
                }
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
            try? await vlcVideoViewModel.download()
        }
    }
}

#if DEBUG
struct VLCContainerView_Previews: PreviewProvider {
    static var previews: some View {
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
}
#endif
