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
    let url: URL
    var preview: Bool = false
    @Binding var play: Bool

    func makeUIView(context: Context) -> UIView {
        return VLCPlayerUIView(frame: .zero,
                               url: url,
                               preview: preview)
    }

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<VLCVideoView>) {
        if let uiView = uiView as? VLCPlayerUIView {
        self.play ? uiView.play() : uiView.pause()

            if let observerTime = context.coordinator.observerTime, time != observerTime {
                uiView.seek(to: time, toleranceBefore: time, toleranceAfter: time, completion: { _ in })
            }
        }
    }

    public static func dismantleUIView(_ uiView: VLCPlayerUIView, coordinator: VLCVideoView.Coordinator) {
        uiView.pause()
    }

    public func makeCoordinator() -> Coordinator {
         Coordinator(self)
     }

    public class Coordinator: NSObject {

           var videoPlayer: VLCVideoView
           var observer: Any?
           var observerTime: CMTime?
           var observerBuffer: Double?

           init(_ videoPlayer: VLCVideoView) {
               self.videoPlayer = videoPlayer
           }

           func startObserver(uiView: VLCVideoView) {
               guard observer == nil else { return }

               observer = uiView.addPeriodicTimeObserver(forInterval: .init(seconds: 0.25, preferredTimescale: 60)) { [weak self, uiView] time in
                   guard let `self` = self else { return }

                   self.videoPlayer.time = time
                   self.observerTime = time

                   self.updateBuffer(uiView: uiView)
               }
           }
    }
}

struct VlcPlayerDemo_Previews: PreviewProvider {
    static var previews: some View {
        let url = URL(string:
                        "http://dl5.webmfiles.org/big-buck-bunny_trailer.webm")!
        VLCVideoView(url: url, play: .constant(true))
    }
}
