//
//  VLCContainerView.swift
//  swiftchan
//
//  Created by vanities on 11/8/20.
//

import SwiftUI
import MobileVLCKit

enum MediaState: Equatable {
    case play
    case pause
    case seek(VLCTime)
}

struct VLCContainerView: View {
    let url: URL
    let autoPlay: Bool
    @Binding var mediaState: MediaState

    @State private var showControls: Bool = true
    @State private var state: VLCMediaPlayerState = .stopped
    @State private var currentTime: VLCTime = VLCTime.init(int: 0)
    @State private var remainingTime: VLCTime = VLCTime.init(int: 0)
    @State private var totalTime: VLCTime = VLCTime.init(int: 0)
    @State private var seeking: Bool = false
    @State private var cachedUrl: URL?

    var onSeekChanged: ((Bool) -> Void)?

    var body: some View {
        return
            ZStack {
                VLCVideoView(url: self.url,
                             autoPlay: self.autoPlay,
                             mediaState: self.$mediaState,
                             state: self.$state,
                             currentTime: self.$currentTime,
                             remainingTime: self.$remainingTime,
                             totalTime: self.$totalTime)
                VStack {
                    Spacer()
                    VLCPlayerControlsView(
                        mediaState: self.$mediaState,
                        state: self.$state,
                        currentTime: self.$currentTime,
                        remainingTime: self.$remainingTime,
                        totalTime: self.$totalTime,
                        seeking: self.$seeking)
                        .padding(.bottom, 25)
                        .onChange(of: self.seeking) { self.onSeekChanged?($0) }
                }
                .opacity(self.showControls ? 1 : 0)

            }
            .onChange(of: self.mediaState) { state in
                if state == .play {
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                        withAnimation(.linear(duration: 0.2)) {
                            self.showControls = false
                        }
                    }
                }
            }
            .onTapGesture {
                withAnimation(.linear(duration: 0.2)) {
                    self.showControls.toggle()
                }
            }
    }
}

extension VLCContainerView: Buildable {
    func onSeekChanged(_ callback: ((Bool) -> Void)?) -> Self {
        mutating(keyPath: \.onSeekChanged, value: callback)
    }
}

struct VLCContainerView_Previews: PreviewProvider {
    static var previews: some View {
        return VLCContainerView(url: URLExamples.webm,
                                autoPlay: true,
                                mediaState: .constant(.play)
        )
        .background(Color.black)
    }
}
