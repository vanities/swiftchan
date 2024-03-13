//
//  VLCPlayerControlsView.swift
//  swiftchan
//
//  Created by vanities on 11/8/20.
//

import SwiftUI
import MobileVLCKit
import SwiftUIIntrospect

struct VLCPlayerControlModifier: ViewModifier {
    @EnvironmentObject var vlcVideoViewModel: VLCVideoViewModel

    @Binding var presenting: Bool
    var onSeekChanged: ((Bool) -> Void)?

    func body(content: Content) -> some View {

        return ZStack {
            content
                .simultaneousGesture(showControlGesture)
            VStack {
                Spacer()
                VLCPlayerControlsView()
                    .padding(.bottom, 25)
                    .onChange(of: vlcVideoViewModel.video.seeking) { onSeekChanged?(vlcVideoViewModel.video.seeking) }
                    .environmentObject(vlcVideoViewModel)
                    .opacity(presenting ? 1 : 0)
            }
        }
    }

    private var showControlGesture: some Gesture {
        TapGesture()
            .onEnded {_ in
                showControls()
            }
    }

    private func showControls() {
        withAnimation(.linear(duration: 0.2)) {
            presenting.toggle()
        }
    }

}

struct VLCPlayerControlsView: View {
    @EnvironmentObject var vlcVideoViewModel: VLCVideoViewModel

    @State private var seekingTime: VLCTime = VLCTime(int: 0)
    @State private var sliderPos: CGFloat = 0

    private var calcSliderPos: CGFloat {
        guard vlcVideoViewModel.video.totalTime.intValue != 0 else { return .zero }
        return CGFloat(vlcVideoViewModel.video.currentTime.intValue) / CGFloat(vlcVideoViewModel.video.totalTime.intValue)
    }

    private var playbackImage: String {
        switch vlcVideoViewModel.video.mediaPlayerState {
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
            Text(vlcVideoViewModel.video.currentTime.description)
                .fixedSize()

            Slider(value: $sliderPos,
                   in: 0...1,
                   onEditingChanged: sliderEditingChanged)
                .onChange(of: vlcVideoViewModel.video.currentTime) {
                    if !vlcVideoViewModel.video.seeking {
                        sliderPos = calcSliderPos
                    }
                }
                .onChange(of: sliderPos) {
                    if vlcVideoViewModel.video.seeking {
                        let currentTime = Int32(CGFloat(vlcVideoViewModel.video.totalTime.intValue) * sliderPos)
                        let currentVLCTime = VLCTime(int: currentTime)
                        let remainingVLCTime = VLCTime(int: currentTime - Int32(vlcVideoViewModel.video.totalTime.intValue))
                        if let currentVLCTime, let remainingVLCTime {
                            vlcVideoViewModel.updateTime(current: currentVLCTime, remaining: remainingVLCTime)
                            vlcVideoViewModel.setMediaControlState(.seek(VLCTime(int: currentTime)))
                        }
                    }
                }
                .introspect(.slider, on: .iOS(.v17)) { slider in
                    slider.setThumbImage(getBiggerSliderButton(), for: .normal)
                }

            Text(vlcVideoViewModel.video.remainingTime.description)
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
        switch vlcVideoViewModel.video.mediaPlayerState {
        case .ended, .stopped:
            break
        case .paused:
            vlcVideoViewModel.resume()
        case .playing, .buffering:
            vlcVideoViewModel.pause()
        default:
            break
        }
    }

    private func sliderEditingChanged(editingStarted: Bool) {
        if editingStarted {
            vlcVideoViewModel.setSeeking(true)
            vlcVideoViewModel.pause()
        }

        if !editingStarted {
            vlcVideoViewModel.setSeeking(false)
            vlcVideoViewModel.resume()
        }
    }
}

extension VLCPlayerControlModifier: Buildable {
    func onSeekChanged(_ callback: ((Bool) -> Void)?) -> Self {
        mutating(keyPath: \.onSeekChanged, value: callback)
    }
}

extension View {
    func playerControl(
        presenting: Binding<Bool>,
        onSeekChanged: ((Bool) -> Void)? = nil
    ) -> some View {
        modifier(VLCPlayerControlModifier(
            presenting: presenting,
            onSeekChanged: onSeekChanged
        ))
    }
}

#if DEBUG
struct VLCPlayerControlsView_Previews: PreviewProvider {
    static var previews: some View {
        let url = URL(string: "google.com")!
        Group {
            Color.green
                .environmentObject(VLCVideoViewModel(url: url))
                .playerControl(
                    presenting: .constant(true),
                    onSeekChanged: {_ in }
                )

            VLCPlayerControlsView()
                .environmentObject(VLCVideoViewModel(url: url))
                .background(Color.black)
        }
    }
}
#endif
