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
            ScrollView(.horizontal,
                       showsIndicators: false) {
                ScrollViewReader { value in
                    HStack(alignment: .center,
                           spacing: nil) {
                        ForEach(self.urls.indices, id: \.self) { index in
                            ThumbnailMediaView(
                                url: urls[index],
                                thumbnailUrl: urls[index])
                                .onTapGesture {
                                    withAnimation(.linear(duration: 0.2)) {
                                        self.selection = index
                                    }
                                }
                                .id(index)
                                .border(self.selection == index ? Color.green : Color.clear, width: 3)
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
        GalleryPreviewView(urls: URLExamples.imageSet,
                           selection: .constant(0))
    }
}
