//
//  VLCVideoView.swift
//  swiftchan
//
//  Created by vanities on 11/6/20.
//

import AVFoundation
import SwiftUI
import MobileVLCKit

struct VLCVideoView: UIViewRepresentable {
    let player: VLCMediaPlayer
    let url: URL
    let autoPlay: Bool

    @Binding private(set) var preview: UIImage
    @Binding private(set) var state: VLCMediaPlayerState
    @Binding private(set) var videoPos: VLCTime
    @Binding private(set) var remainingTime: VLCTime
    @Binding private(set) var seeking: Bool

    func makeUIView(context: Context) -> UIView {
        let vlc = VLCPlayerUIView(frame: .zero,
                                  player: self.player,
                                  url: self.url,
                                  autoPlay: self.autoPlay)
        vlc.delegate = context.coordinator
        return vlc
    }

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<VLCVideoView>) {
        if let player = uiView as? VLCPlayerUIView {
        }
    }

    public static func dismantleUIView(_ uiView: VLCPlayerUIView, coordinator: VLCVideoView.Coordinator) {
        uiView.pause()
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, VLCPlayerUIViewDelegate, VLCMediaPlayerDelegate {
        var parent: VLCVideoView

        init(_ parent: VLCVideoView) {
            self.parent = parent
        }

        func onStateChange(state: VLCMediaPlayerState) {
            self.parent.state = state
        }

        func onPlayerTimeChange(time: VLCTime) {
            self.parent.videoPos = time
            self.parent.remainingTime = self.parent.player.remainingTime
        }

        func onSnapshot(snapshot: UIImage) {
            self.parent.preview = snapshot
        }
    }
}

struct VlcPlayerDemo_Previews: PreviewProvider {
    static var previews: some View {
        let url = URL(string:
                        "http://dl5.webmfiles.org/big-buck-bunny_trailer.webm")!

        return ZStack {
            VLCVideoView(player: VLCMediaPlayer(),
                         url: url,
                         autoPlay: true,
                         preview: .constant(.init()),
                         state: .constant(.playing),
                         videoPos: .constant(.init(int: 0)),
                         remainingTime: .constant(.init(int: 0)),
                         seeking: .constant(false)
            )
        }
    }
}
