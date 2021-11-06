//
//  VLCPlayerControlsView.swift
//  swiftchan
//
//  Created by vanities on 11/8/20.
//

import SwiftUI
import MobileVLCKit

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

            Text(vlcVideoViewModel.vlcVideo.remainingTime.description)
                .fixedSize()
        }
        .foregroundColor(.white)
        .padding(.trailing, 20)
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

#if DEBUG
struct VLCPlayerControlsView_Previews: PreviewProvider {
    static var previews: some View {
        VLCPlayerControlsView()
            .environmentObject(VLCVideoViewModel())
            .background(Color.black)
    }
}
#endif
