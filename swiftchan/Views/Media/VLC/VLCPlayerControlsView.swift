//
//  VLCPlayerControlsView.swift
//  swiftchan
//
//  Created by vanities on 11/8/20.
//

import SwiftUI

import MobileVLCKit

struct VLCPlayerControlsView: View {
    @Binding private(set) var player: VLCMediaPlayer
    @Binding private(set) var state: VLCMediaPlayerState
    @Binding private(set) var videoPos: VLCTime
    @Binding private(set) var remainingTime: VLCTime
    @Binding private(set) var seeking: Bool

    @State private var playerPaused = true
    @State private var sliderPos: CGFloat = 0

    private var totalDuration: CGFloat {
        get {
            CGFloat(abs(self.remainingTime.intValue)) + CGFloat(self.videoPos.intValue)
        }
    }
    private var calcSliderPos: CGFloat {
        get {
            if totalDuration != 0 {
                return CGFloat(self.videoPos.intValue) / self.totalDuration
            }
            return 0
        }
    }

    private var playbackImage: String {
        get {
            switch self.state {
            case .ended, .stopped:
                return "gobackward"
            case .paused:
                return "play"
            case .playing, .buffering:
                return "pause"
            default:
                return ""
            }
        }
    }

    var body: some View {
        return HStack(alignment: .center) {
            Button(action: self.togglePlayPause) {
                Image(systemName: self.playbackImage)
                    .font(Font.system(size: 25))
                    .padding()
            }

            Text(videoPos.description)
                .fixedSize()

            Slider(value: self.$sliderPos,
                   in: 0...1,
                   onEditingChanged: self.sliderEditingChanged)
                .onChange(of: self.videoPos, perform: { _ in
                    self.sliderPos = self.calcSliderPos
                })

            Text(remainingTime.description)
                .fixedSize()
        }
        .foregroundColor(.white)
        .padding(.trailing, 20)
    }

    private func togglePlayPause() {
        self.pausePlayer(!playerPaused)
    }

    private func pausePlayer(_ pause: Bool) {
        print(self.state.rawValue)
        playerPaused = pause

        switch self.state {
        case .ended, .stopped:
            self.player.restart()
        case .paused:
            self.player.play()
            break
        case .playing, .buffering:
            self.player.pause()
            break
        default:
            break
        }
    }

    private func sliderEditingChanged(editingStarted: Bool) {
        if editingStarted {
            seeking = true
            pausePlayer(true)
        }

        if !editingStarted {
            videoPos = VLCTime(number: self.calcSliderPos * self.totalDuration as NSNumber)
            self.pausePlayer(false)
        }
    }
}

struct VLCPlayerControlsView_Previews: PreviewProvider {
    static var previews: some View {
        VLCPlayerControlsView(player: .constant(VLCMediaPlayer()),
                              state: .constant(.ended),
                              videoPos: .constant(.init(int: 5000)),
                              remainingTime: .constant(.init(int: -10000)),
                              seeking: .constant(false)
        )
        .background(Color.black)
    }
}
