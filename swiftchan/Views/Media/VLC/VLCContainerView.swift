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
    let thumbnailUrl: URL
    let url: URL
    let jumpInterval: Int32 = 5

    @Binding var play: Bool
    @StateObject var vlcVideoViewModel = VLCVideoViewModel()
    @State var isShowingControls: Bool = false
    @State var presentingjumpToast: VLCVideo.MediaControlDirection?

    var onSeekChanged: ((Bool) -> Void)?

    var body: some View {
        return ZStack {
            VLCVideoView()
                .environmentObject(vlcVideoViewModel)

            jumpToast

            VStack {
                jumpControls
                Spacer()
                VLCPlayerControlsView()
                    .environmentObject(vlcVideoViewModel)
                    .padding(.bottom, 25)
                    .onChange(of: vlcVideoViewModel.vlcVideo.seeking) { onSeekChanged?($0) }
                    .opacity(isShowingControls ? 1 : 0)
            }

            if vlcVideoViewModel.vlcVideo.mediaState == .buffering {
                ActivityIndicator()
            }
        }
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
            UIApplication.shared.isIdleTimerDisabled = true
            vlcVideoViewModel.vlcVideo.url = url
            vlcVideoViewModel.setCachedMediaPlayer(url: url)
            if play {
                vlcVideoViewModel.vlcVideo.mediaControlState = .play
            }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    private var jumpControls: some View {
        HStack {
            // https://stackoverflow.com/questions/56819847/tap-action-not-working-when-color-is-clear-swiftui
                Color.black.opacity(0.0001)
                    .highPriorityGesture(jumpGesture(.backward))
                    .simultaneousGesture(showControlGesture)
                Color.black.opacity(0.0001)
                    .highPriorityGesture(jumpGesture(.forward))
                    .simultaneousGesture(showControlGesture)
        }
    }

    private var jumpToast: some View {
        let gradient = Gradient(stops: [
            .init(color: .white.opacity(0.2), location: 0),
            .init(color: .clear, location: 0.5)
        ])

        return HStack {
            if presentingjumpToast == .backward {
                ZStack {
                    LinearGradient(
                        gradient: gradient,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                        .cornerRadius(200)

                    HStack {
                        jumpToast(direction: .backward)
                            .padding(20)
                        Spacer()
                    }
                }
            }
            if presentingjumpToast == .forward {
                ZStack {
                    Spacer()
                    LinearGradient(
                        gradient: gradient,
                        startPoint: .trailing,
                        endPoint: .leading
                    )
                        .cornerRadius(200)
                    HStack {
                        Spacer()
                        jumpToast(direction: .forward)
                            .padding(20)

                    }
                }
            }

        }
        .transition(.opacity)
    }

    private var showControlGesture: some Gesture {
        TapGesture()
            .onEnded {
                showControls()
            }
    }

    private func jumpToast(direction: VLCVideo.MediaControlDirection) -> some View {
        AnimatedImage(
            [
                Image(systemName: "arrowtriangle.\(direction.rawValue)"),
                Image(systemName: direction.rawValue)
            ],
            interval: 0.1,
            finished: {
                withAnimation {
                    presentingjumpToast = nil
                }
            })
            .font(.system(size: 32))
            .foregroundColor(.white)
    }

    private func showControls() {
        withAnimation(.linear(duration: 0.2)) {
            isShowingControls.toggle()
        }
    }

    private func jumpGesture(_ direction: VLCVideo.MediaControlDirection) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                if presentingjumpToast == nil {
                    withAnimation {
                        presentingjumpToast = direction
                    }
                    switch direction {
                    case .backward:
                        jumpBackward()
                    case .forward:
                        jumpForward()
                    }
                } else {
                    presentingjumpToast = nil
                }
            }
    }

    private func jumpBackward() {
        vlcVideoViewModel.vlcVideo.mediaControlState = .jump(.backward, jumpInterval)
    }

    private func jumpForward() {
        vlcVideoViewModel.vlcVideo.mediaControlState = .jump(.forward, jumpInterval)
    }
}

extension VLCContainerView: Buildable {
    func onSeekChanged(_ callback: ((Bool) -> Void)?) -> Self {
        mutating(keyPath: \.onSeekChanged, value: callback)
    }
}

struct VLCContainerView_Previews: PreviewProvider {
    static var previews: some View {
        return Group {
            VLCContainerView(
                thumbnailUrl: URLExamples.image,
                url: URLExamples.webm,
                play: .constant(true)
            )
                .background(Color.black)
                .previewInterfaceOrientation(.portrait)

            VLCContainerView(
                thumbnailUrl: URLExamples.image,
                url: URLExamples.webm,
                play: .constant(true),
                presentingjumpToast: .forward
            )
                .background(Color.black)
                .previewInterfaceOrientation(.portrait)

            VLCContainerView(
                thumbnailUrl: URLExamples.image,
                url: URLExamples.webm,
                play: .constant(true),
                presentingjumpToast: .backward
            )
                .background(Color.black)
                .previewInterfaceOrientation(.portrait)
        }
    }
}
