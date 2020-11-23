//
//  GalleryPreviewView.swift
//  swiftchan
//
//  Created by vanities on 11/6/20.
//

import SwiftUI

struct GalleryPreviewView: View {
    let urls: [URL]
    let thumbnailUrls: [URL]

    @Binding var selection: Int

    var body: some View {
        return
            ScrollView(.horizontal,
                       showsIndicators: false) {
                ScrollViewReader { value in
                    HStack(alignment: .center,
                           spacing: nil) {
                        ForEach(self.urls.indices, id: \.self) { index in

                            let url = self.urls[index]
                            let thumbnailUrl = self.thumbnailUrls[index]

                            ThumbnailMediaView(
                                url: url,
                                thumbnailUrl: thumbnailUrl,
                                useThumbnailGif: true)
                                .onTapGesture {
                                    self.selection = index
                                }
                                .id(index)
                                .border(self.selection == index ? Color.green : Color.clear, width: 2)
                                .frame(width: UIScreen.main.bounds.width/5)
                        }
                    }
                    .onChange(of: self.selection, perform: { i in
                        withAnimation(.linear(duration: 0.2)) {
                            value.scrollTo(i)
                        }
                    })
                }
            }
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height / 10)
    }
}

struct GalleryPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GalleryPreviewView(urls: URLExamples.imageSet,
                               thumbnailUrls: URLExamples.imageSet,
                               selection: .constant(0))
            GalleryPreviewView(urls: URLExamples.gifSet,
                               thumbnailUrls: URLExamples.imageSet,
                               selection: .constant(0))
            GalleryPreviewView(urls: URLExamples.webmSet,
                               thumbnailUrls: URLExamples.imageSet,
                               selection: .constant(0))
        }
    }
}
