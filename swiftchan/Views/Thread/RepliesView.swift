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

    @EnvironmentObject private var presentationState: PresentationState
    @EnvironmentObject private var viewModel: ThreadViewModel

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
                .environmentObject(viewModel)
                .environmentObject(presentationState)
        }
    }
}

#if DEBUG
struct RepliesView_Previews: PreviewProvider {

    static var previews: some View {
        let viewModel = ThreadViewModel(boardName: "g", id: 76759434)
        RepliesView(replies: [0, 1])
            .environmentObject(viewModel)
    }
}
#endif
