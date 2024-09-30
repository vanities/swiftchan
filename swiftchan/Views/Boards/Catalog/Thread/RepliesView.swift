//
//  RepliesView.swift
//  swiftchan
//
//  Created by vanities on 11/19/20.
//

import SwiftUI

struct RepliesView: View {
    let replies: [Int]

    let columns = [GridItem(.flexible(), spacing: 0, alignment: .center)]

    @State private var showReply: Bool = false
    @State private var replyId: Int = 0

    @Environment(PresentationState.self) private var presentationState: PresentationState
    @Environment(ThreadViewModel.self) private var viewModel

    var body: some View {
        return ScrollView(.vertical, showsIndicators: true) {
            LazyVGrid(columns: columns,
                      alignment: .center,
                      spacing: 0) {
                ForEach(replies, id: \.self) { index in
                    PostView(index: index)
                }
            }
        }
        .onOpenURL { url in
            if case .post(let id) = Deeplinker.getType(url: url) {
                showReply = true
                replyId = viewModel.getPostIndexFromId(id)
            }
        }
        .navigationDestination(isPresented: $showReply) {
            PostView(index: replyId)
                .environment(viewModel)
                .environment(presentationState)
        }
    }
}

#if DEBUG
#Preview {
    let viewModel = ThreadViewModel(boardName: "g", id: 76759434)
    return RepliesView(replies: [0, 1])
        .environment(viewModel)
}
#endif
