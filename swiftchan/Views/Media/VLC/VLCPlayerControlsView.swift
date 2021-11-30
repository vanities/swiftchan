//
//  VLCPlayerControlsView.swift
//  swiftchan
//
//  Created by vanities on 11/8/20.
//

import SwiftUI
import MobileVLCKit

extension View {
    func playerControl(
        presenting: Binding<Bool>,
        onSeekChanged: ((Bool) -> Void)? = nil
    ) -> some View {
        modifier(VLCPlayerControlViewModifier(
            isShowingControls: presenting,
            onSeekChanged: onSeekChanged
        ))
    }
}

struct VLCPlayerControlViewModifier: ViewModifier {
    @EnvironmentObject private var vlcVideoViewModel: VLCVideoViewModel
    @Binding var isShowingControls: Bool
    var onSeekChanged: ((Bool) -> Void)?

    func body(content: Content) -> some View {

        return ZStack {
            content

            Color.black.opacity(0.0001)
                .highPriorityGesture(showControlGesture)
            // https://stackoverflow.com/questions/56819847/tap-action-not-working-when-color-is-clear-swiftui
            VStack {
                Spacer()
                VLCPlayerControlsView()
                    .padding(.bottom, 25)
                    .onChange(of: vlcVideoViewModel.vlcVideo.seeking) { onSeekChanged?($0) }
                    .opacity(isShowingControls ? 1 : 0)
            }
        }
    }

    private var showControlGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.1, maximumDistance: 1)
            .onEnded {_ in
                showControls()
            }
    }

    private func showControls() {
        withAnimation(.linear(duration: 0.2)) {
            isShowingControls.toggle()
        }
    }

}

struct VLCPlayerControlsView: View {
    @EnvironmentObject var vlcVideoViewModel: VLCVideoViewModel

    @State private var seekingTime: VLCTime = VLCTime(int: 0)
    @State private var sliderPos: CGFloat = 0

    private var calcSliderPos: CGFloat {
        guard vlcVideoViewModel.vlcVideo.totalTime.intValue != 0 else { return .zero }
        return CGFloat(vlcVideoViewModel.vlcVideo.currentTime.intValue) / CGFloat(vlcVideoViewModel.vlcVideo.totalTime.intValue)
    }

    private var playbackImage: String {
        switch vlcVideoViewModel.vlcVideo.mediaPlayerState {
        case .ended, .stopped:
            return "stop"
        case .paused:
            return "play"
        case .playing, .buffering:
            return "pause"
        default:
            return "pause"
        }
    }

    var body: some View {
        return HStack(alignment: .center) {
            Button(action: togglePlayer) {
                Image(systemName: playbackImage)
                    .font(Font.system(size: 25))
                    .padding()
            }

            Text(vlcVideoViewModel.vlcVideo.currentTime.description)
                .fixedSize()

            Slider(value: $sliderPos,
                   in: 0...1,
                   onEditingChanged: sliderEditingChanged)
                .onChange(of: vlcVideoViewModel.vlcVideo.currentTime, perform: { _ in
                    if !vlcVideoViewModel.vlcVideo.seeking {
                        sliderPos = calcSliderPos
                    }
                })
                .onChange(of: sliderPos, perform: { _ in
                    if vlcVideoViewModel.vlcVideo.seeking {
                        let currentTime = Int32(CGFloat(vlcVideoViewModel.vlcVideo.totalTime.intValue) * sliderPos)
                        vlcVideoViewModel.vlcVideo.currentTime = VLCTime(int: currentTime)
                        vlcVideoViewModel.vlcVideo.remainingTime = VLCTime(int: currentTime - Int32(vlcVideoViewModel.vlcVideo.totalTime.intValue))
                        seekingTime = VLCTime(int: currentTime)
                        vlcVideoViewModel.vlcVideo.mediaControlState = .seek(seekingTime)
                    }
                })
                .introspectSlider { slider in
                    slider.setThumbImage(getBiggerSliderButton(), for: .normal)

                }

            Text(vlcVideoViewModel.vlcVideo.remainingTime.description)
                .fixedSize()
        }
        .foregroundColor(.white)
        .padding(.trailing, 20)
    }

    private func getBiggerSliderButton() -> UIImage? {
        return makeCircleWith(size: CGSize(width: 35, height: 35), backgroundColor: UIColor.white)
    }

    fileprivate func makeCircleWith(size: CGSize, backgroundColor: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(backgroundColor.cgColor)
        context?.setStrokeColor(UIColor.clear.cgColor)
        let bounds = CGRect(origin: .zero, size: size)
        context?.addEllipse(in: bounds)
        context?.drawPath(using: .fill)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    private func togglePlayer() {
        switch vlcVideoViewModel.vlcVideo.mediaPlayerState {
        case .ended, .stopped:
            break
        case .paused:
            vlcVideoViewModel.vlcVideo.mediaControlState = .play
        case .playing, .buffering:
            vlcVideoViewModel.vlcVideo.mediaControlState = .pause
        default:
            break
        }
    }

    private func sliderEditingChanged(editingStarted: Bool) {
        if editingStarted {
            vlcVideoViewModel.vlcVideo.seeking = true
            vlcVideoViewModel.vlcVideo.mediaControlState = .pause
        }

        if !editingStarted {
            vlcVideoViewModel.vlcVideo.seeking = false
            vlcVideoViewModel.vlcVideo.mediaControlState = .play
        }
    }
}

extension VLCPlayerControlViewModifier: Buildable {
    func onSeekChanged(_ callback: ((Bool) -> Void)?) -> Self {
        mutating(keyPath: \.onSeekChanged, value: callback)
    }
}

#if DEBUG
struct VLCPlayerControlsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Color.green
                .playerControl(presenting: .constant(true), onSeekChanged: {_ in })
                .environmentObject(VLCVideoViewModel())

            VLCPlayerControlsView()
                .environmentObject(VLCVideoViewModel())
                .background(Color.black)
        }
    }
}
#endif
