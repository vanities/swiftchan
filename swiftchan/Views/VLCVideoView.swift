//
//  VLCVideoView.swift
//  swiftchan
//
//  Created by vanities on 11/6/20.
//

import SwiftUI

struct VLCVideoView: UIViewRepresentable{
    let url: URL
    var preview: Bool = false

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<VLCVideoView>) {
        if let view = uiView as? VLCPlayerUIView {
        }
    }
    
    func makeUIView(context: Context) -> UIView {
        return VLCPlayerUIView(frame: .zero,
                               url: url,
                               preview: preview)
    }
}


struct VlcPlayerDemo_Previews: PreviewProvider {
    static var previews: some View {
        let url = URL(string:
                        "http://dl5.webmfiles.org/big-buck-bunny_trailer.webm")!
        VLCVideoView(url: url
                     )
    }
}
