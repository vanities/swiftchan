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
            ScrollViewReader { value in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .center,
                           spacing: nil) {
                        ForEach(urls.indices, id: \.self) { index in

                            let url = urls[index]
                            let thumbnailUrl = thumbnailUrls[index]

                            ThumbnailMediaView(
                                url: url,
                                thumbnailUrl: thumbnailUrl,
                                useThumbnailGif: true)
                                .onTapGesture {
                                    selection = index
                                }
                                .id(index)
                                .border(selection == index ? Color.green : Color.clear, width: 2)
                                .frame(width: UIScreen.main.bounds.width/5)
                        }
                    }
                    .onChange(of: selection) { index in
                        withAnimation(.linear(duration: 0.2)) {
                            value.scrollTo(index)
                        }
                    }
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
