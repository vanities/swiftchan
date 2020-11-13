//
//  GIFView.swift
//  swiftchan
//
//  Created by vanities on 11/7/20.
//

import SwiftUI
import SwiftyGif

struct GIFView: UIViewRepresentable {
    let url: URL

    @Binding var playGif: Bool

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        let loader = UIActivityIndicatorView(style: .medium)
        imageView.setGifFromURL(url, customLoader: loader)
        imageView.frame = .zero
        return imageView
    }

    func updateUIView(_ gifImageView: UIImageView, context: Context) {
        if playGif == true {
            gifImageView.startAnimatingGif()
        } else {
            gifImageView.stopAnimatingGif()
        }
    }
}

struct GIFView_Previews: PreviewProvider {
    static var previews: some View {
        GIFView(url: URLExamples.gif,
                playGif: .constant(true))
            .frame(width: 250, height: 250)
            .aspectRatio(contentMode: .fit)
    }
}
