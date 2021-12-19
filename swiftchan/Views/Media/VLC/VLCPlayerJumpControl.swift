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
    @EnvironmentObject var vlcVideoViewModel: VLCVideoViewModel

    @State var presentingToastDirection: VLCVideo.MediaControlDirection?

    private let jumpInterval: Int32 = 5

    func body(content: Content) -> some View {
        return ZStack {
            content
                .gesture(jumpGesture)

            VLCPlayerJumpToastView(direction: $presentingToastDirection)
        }
    }

    private func jumpBackward() {
        vlcVideoViewModel.vlcVideo.mediaControlState = .jump(.backward, jumpInterval)
    }

    private func jumpForward() {
        vlcVideoViewModel.vlcVideo.mediaControlState = .jump(.forward, jumpInterval)
    }

    var jumpGesture: some Gesture {
        TapGesture(count: 1).sequenced(
            before:
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onEnded {
                    if $0.location.x > UIScreen.main.bounds.width/2 {
                        jumpForward()

                    } else {
                        jumpBackward()
                    }
                }
        )
    }
}

struct VLCPlayerJumpToastView: View {
    @Binding var direction: VLCVideo.MediaControlDirection?

    private let gradient = Gradient(stops: [
            .init(color: .white.opacity(0.2), location: 0),
            .init(color: .clear, location: 0.5)
        ])

    var body: some View {
        return HStack {
            if direction == .backward {
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
            if direction == .forward {
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

    private func jumpToast(direction: VLCVideo.MediaControlDirection) -> some View {
        AnimatedImage(
            [
                Image(systemName: "arrowtriangle.\(direction.rawValue)"),
                Image(systemName: direction.rawValue)
            ],
            interval: 0.1,
            finished: {
                self.direction = nil
            })
            .font(.system(size: 32))
            .foregroundColor(.white)
    }
}

#if DEBUG
struct VLCPlayerJumpControlView_Previews: PreviewProvider {
    static var previews: some View {
        VLCPlayerJumpToastView(direction: .constant(.backward))
            .environmentObject(VLCVideoViewModel())
            .background(Color.black)
    }
}
#endif
