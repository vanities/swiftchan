//
//  VLCPlayerJumpControl.swift
//  swiftchan
//
//  Created by Adam Mischke on 11/21/21.
//

import SwiftUI
import MobileVLCKit

extension View {
    func jumpControl() -> some View {
        modifier(VLCPlayerJumpControlModifier())
    }
}

struct VLCPlayerJumpControlModifier: ViewModifier {
    func body(content: Content) -> some View {
        return ZStack {
            content
            VLCPlayerJumpControlView()
        }
    }
}

struct VLCPlayerJumpControlView: View {
    @EnvironmentObject private var vlcVideoViewModel: VLCVideoViewModel
    @State private(set) var presentingjumpToast: VLCVideo.MediaControlDirection?
    private let jumpInterval: Int32 = 5

    var body: some View {
        jumpToast
        HStack {
            // https://stackoverflow.com/questions/56819847/tap-action-not-working-when-color-is-clear-swiftui
            Color.black.opacity(0.0001)
                .simultaneousGesture(jumpGesture(.backward))
            Color.black.opacity(0.0001)
                .simultaneousGesture(jumpGesture(.backward))
                //.highPriorityGesture(jumpGesture(.forward))
        }
    }

    private func jumpBackward() {
        vlcVideoViewModel.vlcVideo.mediaControlState = .jump(.backward, jumpInterval)
    }

    private func jumpForward() {
        vlcVideoViewModel.vlcVideo.mediaControlState = .jump(.forward, jumpInterval)
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
}

#if DEBUG
struct VLCPlayerJumpControlView_Previews: PreviewProvider {
    static var previews: some View {
        VLCPlayerJumpControlView()
            .environmentObject(VLCVideoViewModel())
            .background(Color.black)
    }
}
#endif
