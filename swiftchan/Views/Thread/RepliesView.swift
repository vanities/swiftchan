//
//  RepliesView.swift
//  swiftchan
//
//  Created by vanities on 11/19/20.
//

import SwiftUI

struct RepliesView: View {
    let replies: [Int]
    let viewModel: ThreadView.ViewModel

    @State var postIndex: Int = 0
    @State var commentRepliesIndex: Int = 0
    @State var isPresenting = false
    @State var presentingSheet: PresentingSheet = .replies

    let columns = [GridItem(.flexible(), spacing: 0, alignment: .center)]

    var body: some View {
        return
            ZStack(alignment: .center) {
                Blur(style: .regular).ignoresSafeArea()
                ScrollView {
                    LazyVGrid(columns: self.columns,
                              alignment: .center,
                              spacing: 0) {
                        ForEach(self.replies) { index in
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
                            // random id, different from the thread ones
                            .id(UUID())
                        }
                    }
                }.frame(width: UIScreen.main.bounds.width,
                        height: UIScreen.main.bounds.height - SAFE_AREA_PADDING)
                .offset(y: TOP_PADDING)
            }
    }
}

struct RepliesView_Previews: PreviewProvider {

    // TODO: doesn't work
    static var previews: some View {
        let viewModel = ThreadView.ViewModel(boardName: "g", id: 76759434)
        RepliesView(replies: [0, 1], viewModel: viewModel)
    }
}
