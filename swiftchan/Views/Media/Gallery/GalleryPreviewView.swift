//
//  GalleryPreviewView.swift
//  swiftchan
//
//  Created by vanities on 11/6/20.
//

import SwiftUI

struct GalleryPreviewView: View {
    let urls: [URL]

    @Binding var selection: Int

    var body: some View {
        return
            GeometryReader { geo in
                ScrollView(.horizontal,
                           showsIndicators: false) {
                    HStack(alignment: .center,
                           spacing: nil) {
                        ForEach(self.urls.indices, id: \.self) { index in
                            ThumbnailMediaView(url: urls[index],
                                               thumbnailUrl: urls[index],
                                               selected: true)
                                .onTapGesture {
                                    withAnimation(.linear(duration: 0.2)) {
                                        self.selection = index
                                    }
                                }
                        }
                    }
                           }
                .frame(width: geo.size.width, height: geo.size.height / 10)
            }
    }
}

struct GalleryPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        GalleryPreviewView(urls: URLExamples.imageSet,
                           selection: .constant(0))
    }
}
