//
//  GalleryPreviewView.swift
//  swiftchan
//
//  Created by vanities on 11/6/20.
//

import SwiftUI

struct GalleryPreviewView: View {
    @EnvironmentObject var viewModel: ThreadView.ViewModel
    @Binding var selection: Int
    
    var body: some View {
        return
        ScrollViewReader { value in
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

#if DEBUG
struct GalleryPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ThreadView.ViewModel(boardName: "pol", id: 0)
        let urls = [
            URLExamples.image,
            URLExamples.gif,
            URLExamples.webm
        ]
        viewModel.setMedia(mediaUrls: urls, thumbnailMediaUrls: urls)
        
        return Group {
            GalleryPreviewView(selection: .constant(0))
                .environmentObject(viewModel)
            GalleryPreviewView(selection: .constant(1))
                .environmentObject(viewModel)
            GalleryPreviewView(selection: .constant(2))
                .environmentObject(viewModel)
        }
    }
}
#endif
