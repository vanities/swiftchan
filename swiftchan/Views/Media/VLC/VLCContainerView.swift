//
//  VLCContainerView.swift
//  swiftchan
//
//  Created by vanities on 11/8/20.
//

import SwiftUI
import MobileVLCKit

enum MediaState {
    case play
    case pause
    case seek(VLCTime)
}

struct VLCContainerView: View {
    let url: URL
    let autoPlay: Bool
    let play: Bool

    @State private var showControls: Bool = true
    @State private var preview = UIImage()
    @State private var controlState: MediaState = .play
    @State private var state: VLCMediaPlayerState = .stopped
    @State private var currentTime: VLCTime = VLCTime.init(int: 0)
    @State private var remainingTime: VLCTime = VLCTime.init(int: 0)
    @State private var totalTime: VLCTime = VLCTime.init(int: 0)
    @State private var cachedUrl: URL?

    var body: some View {
        return
            ZStack {
                Image(uiImage: preview)
                VLCVideoView(url: url,
                             autoPlay: self.autoPlay,
                             mediaState: self.controlState,
                             state: self.$state,
                             currentTime: self.$currentTime,
                             remainingTime: self.$remainingTime,
                             totalTime: self.$totalTime)
                VStack {
                    Spacer()
                    if self.showControls {
                        VLCPlayerControlsView(
                            mediaState: self.$controlState,
                            state: self.$state,
                            currentTime: self.$currentTime,
                            remainingTime: self.$remainingTime,
                            totalTime: self.$totalTime)
                            .transition(.opacity)
                    }
                }
            }
            .onChange(of: self.play, perform: { shouldPlay in
                self.controlState = shouldPlay ? .play : .pause
            })

            .onTapGesture {
                withAnimation(.linear(duration: 0.2)) {
                    self.showControls.toggle()
                }
            }
    }
}

struct VLCContainerView_Previews: PreviewProvider {
    static var previews: some View {
        return VLCContainerView(url: URLExamples.webm,
                         autoPlay: true,
                         play: true)
            .background(Color.black)
    }
}
