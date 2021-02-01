//
//  VLCPlayerControlsView.swift
//  swiftchan
//
//  Created by vanities on 11/8/20.
//

import SwiftUI
import MobileVLCKit

struct VLCPlayerControlsView: View {
    @EnvironmentObject var video: VLCVideo

    @State private var seekingTime: VLCTime = VLCTime(int: 0)
    @State private var sliderPos: CGFloat = 0

    private var calcSliderPos: CGFloat {
            guard self.video.totalTime.intValue != 0 else { return .zero }
            return CGFloat(self.video.currentTime.intValue) / CGFloat(self.video.totalTime.intValue)
    }

    private var playbackImage: String {
            switch self.video.state {
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
            Button(action: self.togglePlayer) {
                Image(systemName: self.playbackImage)
                    .font(Font.system(size: 25))
                    .padding()
            }

            Text(self.video.currentTime.description)
                .fixedSize()

            Slider(value: self.$sliderPos,
                   in: 0...1,
                   onEditingChanged: self.sliderEditingChanged)
                .onChange(of: self.video.currentTime, perform: { _ in
                    if !self.video.seeking {
                        self.sliderPos = self.calcSliderPos
                    }
                })
                .onChange(of: self.sliderPos, perform: { _ in
                    if self.video.seeking {
                        let currentTime = Int32(CGFloat(self.video.totalTime.intValue) * self.sliderPos)
                        self.video.currentTime = VLCTime(int: currentTime)
                        self.video.remainingTime = VLCTime(int: currentTime - Int32(self.video.totalTime.intValue))
                        self.seekingTime = VLCTime(int: currentTime)
                        self.video.mediaState = .seek(self.seekingTime)
                    }
                })

            Text(self.video.remainingTime.description)
                .fixedSize()
        }
        .foregroundColor(.white)
        .padding(.trailing, 20)
    }

    private func togglePlayer() {
        switch self.video.state {
        case .ended, .stopped:
            break
        case .paused:
            self.video.mediaState = .play
        case .playing, .buffering:
            self.video.mediaState = .pause
        default:
            break
        }
    }

    private func sliderEditingChanged(editingStarted: Bool) {
        if editingStarted {
            self.video.seeking = true
            self.video.mediaState = .pause
        }

        if !editingStarted {
            self.video.seeking = false
            self.video.mediaState = .play
        }
    }
}

struct VLCPlayerControlsView_Previews: PreviewProvider {
    static var previews: some View {
        VLCPlayerControlsView()
            .environmentObject(VLCVideo())
            .background(Color.black)
    }
}
