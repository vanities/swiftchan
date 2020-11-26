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

    @State private var pullToRefreshShowing: Bool = false

    let columns = [GridItem(.flexible(), spacing: 0, alignment: .center)]

    var body: some View {
        return ZStack {
            ScrollView {
                LazyVGrid(columns: self.columns,
                          alignment: .center,
                          spacing: 0,
                          content: {
                            ForEach(self.viewModel.posts.indices, id: \.self) { index in
                                if index < self.viewModel.comments.count {
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
                            }
                            .frame(minWidth: UIScreen.main.bounds.width)
                          }
                )
            }
            .pullToRefresh(isRefreshing: self.$pullToRefreshShowing) {
                let softVibrate = UIImpactFeedbackGenerator(style: .soft)
                softVibrate.impactOccurred()
                self.viewModel.load {
                    self.pullToRefreshShowing = false
                }
            }

            if self.isPresenting {
                PresentedPost(presenting: self.$isPresenting,
                              presentingSheet: self.presentingSheet,
                              viewModel: self.viewModel,
                              commentRepliesIndex: self.commentRepliesIndex,
                              galleryIndex: self.galleryIndex)
            }
        }
        .navigationBarHidden(self.isPresenting)
        .statusBar(hidden: self.isPresenting)

    }
}

struct ThreadView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ThreadView.ViewModel(boardName: "g", id: 76759434)
        ThreadView(viewModel: viewModel)
    }
}
