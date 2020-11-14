//
//  VLCPlayerControlsView.swift
//  swiftchan
//
//  Created by vanities on 11/8/20.
//

import SwiftUI

import MobileVLCKit

struct VLCPlayerControlsView: View {
    @Binding var mediaState: MediaState
    @Binding private(set) var state: VLCMediaPlayerState
    @Binding private(set) var currentTime: VLCTime
    @Binding private(set) var remainingTime: VLCTime
    @Binding private(set) var totalTime: VLCTime

    @State private var seeking: Bool = false
    @State private var seekingTime: VLCTime = VLCTime(int: 0)
    @State private var sliderPos: CGFloat = 0

    private var calcSliderPos: CGFloat {
        get {
            guard self.totalTime.intValue != 0 else { return .zero }
            return CGFloat(self.currentTime.intValue) / CGFloat(self.totalTime.intValue)
        }
    }

    private var playbackImage: String {
        get {
            switch self.state {
            case .ended, .stopped:
                return "restart"
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
            Button(action: self.togglePlayer) {
                Image(systemName: self.playbackImage)
                    .font(Font.system(size: 25))
                    .padding()
            }

            Text(currentTime.description)
                .fixedSize()

            Slider(value: self.$sliderPos,
                   in: 0...1,
                   onEditingChanged: self.sliderEditingChanged)
                .onChange(of: self.currentTime, perform: { _ in
                    self.sliderPos = self.calcSliderPos
                })
                .onChange(of: self.sliderPos, perform: { _ in
                    if self.seeking {
                        self.seekingTime = VLCTime(int: Int32(CGFloat(self.totalTime.intValue) * self.sliderPos))
                        self.mediaState = .seek(self.seekingTime)
                    }
                })

            Text(remainingTime.description)
                .fixedSize()
        }
        .foregroundColor(.white)
        .padding(.trailing, 20)
    }

    private func togglePlayer() {
        switch self.state {
        case .ended, .stopped:
            self.mediaState = .restart
        case .paused:
            self.mediaState = .play
        case .playing, .buffering:
            self.mediaState = .pause
        default:
            break
        }
    }

    private func sliderEditingChanged(editingStarted: Bool) {
        if editingStarted {
            self.seeking = true
            self.mediaState = .pause
        }

        if !editingStarted {
            self.seeking = false
            self.mediaState = .play
        }
    }
}

struct VLCPlayerControlsView_Previews: PreviewProvider {
    static var previews: some View {
        VLCPlayerControlsView(mediaState: .constant(.play),
                              state: .constant(.playing),
                              currentTime: .constant(.init(int: 0)),
                              remainingTime: .constant(.init(int: 30000)),
                              totalTime: .constant(.init(int: 500000)))
            .background(Color.black)
    }
}
