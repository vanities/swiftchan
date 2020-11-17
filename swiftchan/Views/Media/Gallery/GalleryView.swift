//
//  GalleryView.swift
//  swiftchan
//
//  Created by vanities on 11/5/20.
//

import SwiftUI

struct GalleryView: View {
    @Binding var selection: Int
    var urls: [URL]
    var thumbnailUrls: [URL]

    var body: some View {
        return ZStack {
            // background
            Color.black
                .edgesIgnoringSafeArea(.all)
            // media
            TabView(selection: self.$selection) {
                ForEach(self.urls.indices, id: \.self) { index in
                    let url = self.urls[index]
                    MediaView(url: url,
                              selected: self.selection == index,
                              autoPlay: true)
                        .tag(index)
                }
            }
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .never))
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .tabViewStyle(PageTabViewStyle())
            // preview
            VStack {
                Spacer()
                GalleryPreviewView(urls: self.thumbnailUrls,
                                   selection: self.$selection)
            }
        }
    }
}

struct GalleryView_Previews: PreviewProvider {
    static var previews: some View {
        GalleryView(selection: .constant(0),
                    urls: Array.init(
                        repeating: URLExamples.image,
                        count: 1),
                    thumbnailUrls: Array.init(
                        repeating: URLExamples.image,
                        count: 1)
        )
    }
}
