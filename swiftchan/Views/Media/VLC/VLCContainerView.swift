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
                    Text("\(Int(vlcVideoViewModel.video.downloadProgress.fractionCompleted * 100))%")
                        .foregroundColor(.white)
                        .font(.title)
                }
            }
            if vlcVideoViewModel.video.downloadProgress.isFinished && vlcVideoViewModel.video.mediaState == .buffering {
                ProgressView("Buffering")
            }
        }
        .playerControl(presenting: $presentingPlayerControl)
        .environment(vlcVideoViewModel)
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
            if isSelected && vlcVideoViewModel.video.downloadProgress.isFinished {
                vlcVideoViewModel.play()
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
            try? await vlcVideoViewModel.download()
            if isSelected {
                vlcVideoViewModel.play()
            }
        }
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

