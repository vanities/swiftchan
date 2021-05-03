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
    @StateObject var vlcVideoViewModel = VLCVideoViewModel()
    @State var showControls: Bool = false

    var onSeekChanged: ((Bool) -> Void)?

    var body: some View {
        return
            ZStack {
                VLCVideoView()
                    .environmentObject(vlcVideoViewModel)
                VStack {
                    Spacer()
                    VLCPlayerControlsView()
                        .environmentObject(vlcVideoViewModel)
                        .padding(.bottom, 25)
                        .onChange(of: vlcVideoViewModel.vlcVideo.seeking) { onSeekChanged?($0) }
                }
                .opacity(showControls ? 1 : 0)

                if vlcVideoViewModel.vlcVideo.state == .playing {
                    ActivityIndicator()
                }
            }
            .onChange(of: vlcVideoViewModel.vlcVideo.mediaState) { state in
                if state == .play {
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                        withAnimation(.linear(duration: 0.2)) {
                            showControls = false
                        }
                    }
                }
            }
            .onTapGesture {
                withAnimation(.linear(duration: 0.2)) {
                    showControls.toggle()
                }
            }
            .onChange(of: self.play) {
                vlcVideoViewModel.vlcVideo.mediaState = $0 ? .play : .pause
            }
            .onAppear {
                vlcVideoViewModel.vlcVideo.url = url
                vlcVideoViewModel.setCachedMediaPlayer(url: url)
                if play {
                    vlcVideoViewModel.vlcVideo.mediaState = .play
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
