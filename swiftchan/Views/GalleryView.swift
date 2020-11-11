//
//  GalleryView.swift
//  swiftchan
//
//  Created by vanities on 11/5/20.
//

import SwiftUI
import URLImage

struct GalleryView: View {
    @State var selection: Int = 0
    var urls: [URL]

    var body: some View {
        return ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            TabView(selection: self.$selection) {
                ForEach(self.urls.indices, id: \.self) { index in
                    let url = self.urls[index]
                    if MediaDetector.isImage(url: url) {
                        ImageView(index: index,
                                  url: url,
                                  isSelected: index == selection)
                    } else if MediaDetector
                                .isWebm(url: url) {
                        VLCContainerView(url: url,
                                         autoPlay: true,
                                         play: index == self.selection)
                    }
                }
            }
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .never))
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .tabViewStyle(PageTabViewStyle())
        }
    }
}

struct GalleryView_Previews: PreviewProvider {
    static var previews: some View {
        GalleryView(urls: Array.init(
                        repeating: URL(string: "https://picsum.photos/1020/900")!,
                        count: 5)
        )
    }
}
