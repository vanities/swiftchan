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
    @EnvironmentObject var viewModel: ViewModel

    @State private var isPresenting = false
    @State private var presentingSheet: PresentingSheet = .gallery

    @State var galleryIndex: Int = 0
    @State var commentRepliesIndex: Int = 0

    @State private var pullToRefreshShowing: Bool = false
    @State private var opacity: Double = 1

    let columns = [GridItem(.flexible(), spacing: 0, alignment: .center)]

    var body: some View {
        return ZStack {
            ScrollView {
                LazyVGrid(columns: self.columns,
                          alignment: .center,
                          spacing: 0) {
                    ForEach(self.viewModel.posts.indices, id: \.self) { index in
                        if index < self.viewModel.comments.count {
                            PostView(index: index,
                                     isPresenting: self.$isPresenting,
                                     presentingSheet: self.$presentingSheet,
                                     galleryIndex: self.$galleryIndex,
                                     commentRepliesIndex: self.$commentRepliesIndex
                            )
                        }
                    }
                    .frame(minWidth: UIScreen.main.bounds.width)
                }
                .opacity(self.opacity)
                .pullToRefresh(isRefreshing: self.$pullToRefreshShowing) {
                    let softVibrate = UIImpactFeedbackGenerator(style: .soft)
                    softVibrate.impactOccurred()
                    self.viewModel.load {
                        self.pullToRefreshShowing = false
                    }
                }
            }

            if self.isPresenting {
                PresentedPost(presenting: self.$isPresenting,
                              presentingSheet: self.presentingSheet,
                              galleryIndex: self.$galleryIndex, commentRepliesIndex: self.commentRepliesIndex)
                    .onOffsetChanged { value in
                        withAnimation(.linear) {
                            self.opacity = Double(value / UIScreen.main.bounds.height)
                        }

                    }
                    .onDisappear {
                        self.opacity = 1
                    }
                    .zIndex(1)
            }
        }
        .navigationBarHidden(self.isPresenting)
        .statusBar(hidden: self.isPresenting)
    }
}

struct ThreadView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ThreadView.ViewModel(boardName: "g", id: 76759434)
        ThreadView()
            .environmentObject(viewModel)
    }
}