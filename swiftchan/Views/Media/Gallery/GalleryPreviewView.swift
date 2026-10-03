//
//  GalleryPreviewView.swift
//  swiftchan
//
//  Created on 11/6/20.
//

import SwiftUI

struct GalleryPreviewView: View {
    @Environment(ThreadViewModel.self) private var viewModel
    @Binding var selection: Int

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.media.indices, id: \.self) { index in
                            let media = viewModel.media[index]
                            ThumbnailMediaView(url: media.url, thumbnailUrl: media.thumbnailUrl)
                                .frame(width: min(120, max(44, geometry.size.width / 5)), height: 88)
                                .clipped()
                                .border(selection == index ? Color.green : Color.clear, width: 2)
                                .contentShape(.rect)
                                .onTapGesture { selection = index }
                                .id(index)
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .onChange(of: selection) {
                    withAnimation(.linear(duration: 0.2)) {
                        proxy.scrollTo(selection, anchor: .center)
                    }
                }
                .onAppear { proxy.scrollTo(selection, anchor: .center) }
            }
        }
        .frame(height: 96)
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
