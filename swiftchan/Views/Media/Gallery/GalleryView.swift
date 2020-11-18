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

    @State var showPreview: Bool = true

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
                              selected: self.selection == index)
                        .tag(index)
                }
            }
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .never))
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .tabViewStyle(PageTabViewStyle())
            // preview
            if self.showPreview {
                VStack {
                    Spacer()
                    GalleryPreviewView(urls: self.thumbnailUrls,
                                       selection: self.$selection)
                        .padding(.bottom, 50)
                }
                .transition(.opacity)
            }
        }
        .onTapGesture {
            withAnimation(.linear(duration: 0.2)) {
                self.showPreview.toggle()
            }
        }
    }
}

struct GalleryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GalleryView(selection: .constant(0),
                        urls: URLExamples.imageSet,
                        thumbnailUrls: URLExamples.imageSet
            )
            GalleryView(selection: .constant(0),
                        urls: URLExamples.webmSet,
                        thumbnailUrls: URLExamples.webmSet
            )
            GalleryView(selection: .constant(0),
                        urls: URLExamples.gifSet,
                        thumbnailUrls: URLExamples.gifSet
            )
        }
    }
}
