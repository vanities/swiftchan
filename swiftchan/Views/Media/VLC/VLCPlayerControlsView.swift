//
//  VLCPlayerControlsView.swift
//  swiftchan
//
//  Created by vanities on 11/8/20.
//

import SwiftUI
import MobileVLCKit

struct VLCPlayerControlsView: View {
    @EnvironmentObject var vlcVideoModel: VLCVideoViewModel

    @State private var seekingTime: VLCTime = VLCTime(int: 0)
    @State private var sliderPos: CGFloat = 0

    private var calcSliderPos: CGFloat {
        guard vlcVideoModel.vlcVideo.totalTime.intValue != 0 else { return .zero }
        return CGFloat(vlcVideoModel.vlcVideo.currentTime.intValue) / CGFloat(vlcVideoModel.vlcVideo.totalTime.intValue)
    }

    private var playbackImage: String {
        switch vlcVideoModel.vlcVideo.state {
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

            Text(vlcVideoModel.vlcVideo.currentTime.description)
                .fixedSize()

            Slider(value: $sliderPos,
                   in: 0...1,
                   onEditingChanged: sliderEditingChanged)
                .onChange(of: vlcVideoModel.vlcVideo.currentTime, perform: { _ in
                    if !vlcVideoModel.vlcVideo.seeking {
                        sliderPos = calcSliderPos
                    }
                })
                .onChange(of: sliderPos, perform: { _ in
                    if vlcVideoModel.vlcVideo.seeking {
                        let currentTime = Int32(CGFloat(vlcVideoModel.vlcVideo.totalTime.intValue) * sliderPos)
                        vlcVideoModel.vlcVideo.currentTime = VLCTime(int: currentTime)
                        vlcVideoModel.vlcVideo.remainingTime = VLCTime(int: currentTime - Int32(vlcVideoModel.vlcVideo.totalTime.intValue))
                        seekingTime = VLCTime(int: currentTime)
                        vlcVideoModel.vlcVideo.mediaState = .seek(seekingTime)
                    }
                })

            Text(vlcVideoModel.vlcVideo.remainingTime.description)
                .fixedSize()
        }
        .foregroundColor(.white)
        .padding(.trailing, 20)
    }

    private func togglePlayer() {
        switch vlcVideoModel.vlcVideo.state {
        case .ended, .stopped:
            break
        case .paused:
            vlcVideoModel.vlcVideo.mediaState = .play
        case .playing, .buffering:
            vlcVideoModel.vlcVideo.mediaState = .pause
        default:
            break
        }
    }

    private func sliderEditingChanged(editingStarted: Bool) {
        if editingStarted {
            vlcVideoModel.vlcVideo.seeking = true
            vlcVideoModel.vlcVideo.mediaState = .pause
        }

        if !editingStarted {
            vlcVideoModel.vlcVideo.seeking = false
            vlcVideoModel.vlcVideo.mediaState = .play
        }
    }
}

struct VLCPlayerControlsView_Previews: PreviewProvider {
    static var previews: some View {
        VLCPlayerControlsView()
            .environmentObject(VLCVideoViewModel())
            .background(Color.black)
    }
}
