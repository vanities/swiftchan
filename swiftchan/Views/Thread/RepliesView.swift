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

    var body: some View {
        return ForEach(self.replies, id: \.self) { index in
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
        }
    }
}

struct RepliesView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ThreadView.ViewModel(boardName: "fit", id: 5551578)
        RepliesView(replies: [0], viewModel: viewModel)
    }
}
