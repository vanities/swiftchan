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
    @Binding var play: Bool
    @StateObject var video = VLCVideoViewModel()
    @State var showControls: Bool = false

    var onSeekChanged: ((Bool) -> Void)?

    var body: some View {
        return
            ZStack {
                VLCVideoView()
                    .environmentObject(video)
                VStack {
                    Spacer()
                    VLCPlayerControlsView()
                        .environmentObject(video)
                        .padding(.bottom, 25)
                        .onChange(of: self.video.seeking) { self.onSeekChanged?($0) }
                }
                .opacity(self.showControls ? 1 : 0)

                if video.state == .playing {
                    ActivityIndicator()
                }
            }
            .onChange(of: self.video.mediaState) { state in
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
            .onChange(of: self.play) {
                self.video.mediaState = $0 ? .play : .pause
            }
            .onAppear {
                self.video.url = self.url
                self.video.setCachedMediaPlayer(url: url)
                if self.play {
                    self.video.mediaState = .play
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
        return VLCContainerView(url: URLExamples.webm, play: .constant(true))
        .background(Color.black)
    }
}
