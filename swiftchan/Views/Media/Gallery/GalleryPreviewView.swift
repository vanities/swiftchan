//
//  GalleryPreviewView.swift
//  swiftchan
//
//  Created by vanities on 11/6/20.
//

import SwiftUI

struct GalleryPreviewView: View {
    @Environment(ThreadViewModel.self) private var viewModel
    @Binding var selection: Int

    var body: some View {
        return ScrollViewReader { value in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .center,
                       spacing: nil) {
                    ForEach(viewModel.media.indices, id: \.self) { index in
                        let media = viewModel.media[index]
                        let url = media.url
                        let thumbnailUrl = media.thumbnailUrl

                        ThumbnailMediaView(
                            url: url,
                            thumbnailUrl: thumbnailUrl
                        )
                        .onTapGesture {
                            selection = index
                        }
                        .id(index)
                        .border(selection == index ? Color.green : Color.clear, width: 2)
                        .frame(width: UIScreen.width/5)
                    }
                }
                       .onChange(of: selection) {
                           withAnimation(.linear(duration: 0.2)) {
                               value.scrollTo(selection)
                           }
                       }
            }
        }
        .frame(width: UIScreen.width, height: UIScreen.height / 10)
    }
}

#if DEBUG
#Preview {
    let viewModel = ThreadViewModel(boardName: "pol", id: 0)
    let urls = [
        URLExamples.image,
        URLExamples.gif,
        URLExamples.webm
    ]
    viewModel.setMedia(mediaUrls: urls, thumbnailMediaUrls: urls)

    return Group {
        GalleryPreviewView(selection: .constant(0))
            .environment(viewModel)
        GalleryPreviewView(selection: .constant(1))
            .environment(viewModel)
        GalleryPreviewView(selection: .constant(2))
            .environment(viewModel)
    }
}
#endif
