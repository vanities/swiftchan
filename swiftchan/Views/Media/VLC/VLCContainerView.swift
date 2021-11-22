//
//  VLCContainerView.swift
//  swiftchan
//
//  Created by vanities on 11/8/20.
//

import SwiftUI
import MobileVLCKit
import ToastUI

struct VLCContainerView: View {
    let url: URL
    @Binding var play: Bool

    @StateObject var vlcVideoViewModel = VLCVideoViewModel()
    @State private var isShowingControls: Bool = false
    @State private(set) var presentingjumpToast: VLCVideo.MediaControlDirection?
    @EnvironmentObject var threadViewModel: ThreadView.ViewModel

    var onSeekChanged: ((Bool) -> Void)?

    var body: some View {
        return ZStack {
            VLCVideoView(url: url)
                .mediaDownloadMenu(url: url)

            if vlcVideoViewModel.vlcVideo.mediaState == .buffering {
                ProgressView()
            }
        }
        .playerControl(presenting: $isShowingControls)
        .jumpControl()
        .environmentObject(vlcVideoViewModel)
        .onChange(of: vlcVideoViewModel.vlcVideo.mediaControlState) { state in
            if state == .play {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                    withAnimation(.linear(duration: 0.2)) {
                        isShowingControls = false
                    }
                }
            }
        }
        .onChange(of: play) {
            vlcVideoViewModel.vlcVideo.mediaControlState = $0 ? .play : .pause
        }
        .onAppear {
            vlcVideoViewModel.vlcVideo.url = url
            vlcVideoViewModel.vlcVideo.id = url
            UIApplication.shared.isIdleTimerDisabled = true
            play = true
        }
        .onDisappear {
            vlcVideoViewModel.vlcVideo.mediaControlState = .pause
            play = false
        }
    }
}

#if DEBUG
struct VLCContainerView_Previews: PreviewProvider {
    static var previews: some View {
        return Group {
            VLCContainerView(
                url: URLExamples.webm,
                play: .constant(true)
            )
                .background(Color.black)
                .previewInterfaceOrientation(.portrait)

            VLCContainerView(
                url: URLExamples.webm,
                play: .constant(true),
                presentingjumpToast: .forward
            )
                .background(Color.black)
                .previewInterfaceOrientation(.portrait)

            VLCContainerView(
                url: URLExamples.webm,
                play: .constant(true),
                presentingjumpToast: .backward
            )
                .background(Color.black)
                .previewInterfaceOrientation(.portrait)
        }
    }
}
#endif
