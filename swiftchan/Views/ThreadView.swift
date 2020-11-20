//
//  ThreadView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI
import FourChan

enum PresentingSheet {
   case gallery, replies
}

struct ThreadView: View {
    @ObservedObject var viewModel: ViewModel

    @State private var isPresenting = false
    @State private var presentingSheet: PresentingSheet = .gallery

    @State var galleryIndex: Int = 0
    @State var commentRepliesIndex: Int = 0

    @State var postIndex: Int = 0

    let columns = [GridItem(.flexible(), spacing: 0, alignment: .center)]

    var body: some View {
        return GeometryReader { geo in
            ZStack {
                ScrollView {
                    LazyVGrid(columns: self.columns,
                              alignment: .center,
                              spacing: 0,
                              content: {
                                ForEach(self.viewModel.posts.indices, id: \.self) { index in
                                    PostView(boardName: self.viewModel.boardName,
                                             post: self.viewModel.posts[index],
                                             index: index,
                                             comment: self.viewModel.comments[index],
                                             replies: self.viewModel.replies[index] ?? nil,
                                             isPresenting: self.$isPresenting,
                                             presentingSheet: self.$presentingSheet,
                                             galleryIndex: self.$postIndex,
                                             commentRepliesIndex: self.$commentRepliesIndex
                                    )
                                    .onChange(of: self.isPresenting, perform: { _ in
                                        if self.postIndex == index && self.presentingSheet == .gallery {
                                            self.galleryIndex = self.viewModel.postMediaMapping[index] ?? 0

                                        }
                                    })
                                }
                                .frame(minWidth: UIScreen.main.bounds.width,
                                       minHeight: geo.size.height/3)
                              }
                    )
                }
            }
        }
        .fullScreenCover(isPresented: self.$isPresenting) {
            ZStack {
            switch self.presentingSheet {
            case .gallery:
                GalleryView(selection: self.$galleryIndex,
                            urls: self.viewModel.mediaUrls,
                            thumbnailUrls: self.viewModel.thumbnailMediaUrls
                )
            case .replies:
                if let replies = self.viewModel.replies[self.commentRepliesIndex] {
                    RepliesView(replies: replies,
                                viewModel: self.viewModel,
                                commentRepliesIndex: self.commentRepliesIndex)
                }
            }
            }
        }
    }
}

struct ThreadView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ThreadView.ViewModel(boardName: "fit", id: 5551578)
        ThreadView(viewModel: viewModel)
    }
}
