//
//  VLCContainerView.swift
//  swiftchan
//
//  Created by vanities on 11/8/20.
//

import SwiftUI
import MobileVLCKit

struct VLCContainerView: View {
    let url: URL
    let autoPlay: Bool
    let play: Bool

    @State private var showControls: Bool = true
    @State private var player = VLCMediaPlayer()
    @State private var preview = UIImage()
    @State private var state = VLCMediaPlayerState(rawValue: 0)!
    @State private var videoPos: VLCTime = VLCTime.init(int: 0)
    @State private var remainingTime: VLCTime = VLCTime.init(int: 0)
    @State private var seeking = false
    @State private var cachedUrl: URL?

    var body: some View {
        if play {
            self.player.play()
        } else {
            self.player.pause()
        }
        return
            ZStack {
                Image(uiImage: preview)
                VLCVideoView(player: self.player,
                             url: url,
                             autoPlay: self.autoPlay,
                             preview: self.$preview,
                             state: self.$state,
                             videoPos: self.$videoPos,
                             remainingTime: self.$remainingTime,
                             seeking: self.$seeking)
                VStack {
                    Spacer()
                    if self.showControls {
                        VLCPlayerControlsView(
                            player: self.$player,
                            state: self.$state,
                            videoPos: self.$videoPos,
                            remainingTime: self.$remainingTime,
                            seeking: self.$seeking)
                            .transition(.opacity)
                    }
                }
            }

            .onTapGesture {
                withAnimation(.linear(duration: 0.2)) {
                    self.showControls.toggle()
                }
            }
            .onDisappear {
                self.player.pause()
            }
    }
}

struct VLCContainerView_Previews: PreviewProvider {
    static var previews: some View {
        let url = URL(string:
                        "http://dl5.webmfiles.org/big-buck-bunny_trailer.webm")!
        return VLCContainerView(url: url,
                         autoPlay: true,
                         play: true)
            .background(Color.black)
    }
}
