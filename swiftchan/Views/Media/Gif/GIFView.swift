//
//  GIFView.swift
//  swiftchan
//
//  Created by vanities on 11/7/20.
//

import SwiftUI

struct GIFView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> UIView {
        return GIFPlayerView(url: url)
    }

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<GIFView>) {
    }

    public static func dismantleUIView(_ uiView: GIFPlayerView, coordinator: Coordinator) {
        uiView.imageView.image = nil
    }
}
