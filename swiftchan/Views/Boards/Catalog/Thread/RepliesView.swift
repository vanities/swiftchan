//
//  RepliesView.swift
//  swiftchan
//
//  Created on 11/19/20.
//

import SwiftUI

struct RepliesView: View {
    let replies: [Int]

    let columns = [GridItem(.flexible(), spacing: 0, alignment: .center)]

    @State private var showReply: Bool = false
    @State private var replyId: Int = 0
    @State private var showPostUnavailable = false
    @Environment(\.openURL) private var openURL

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
        .environment(\.inRepliesContext, true)
        .environment(\.openURL, postLinkAction)
        .alert("Post Unavailable", isPresented: $showPostUnavailable) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This post is not in the loaded thread. It may have been deleted.")
        }
        .navigationDestination(isPresented: $showReply) {
            PostView(index: replyId)
                .environment(viewModel)
                .environment(presentationState)
                .environment(\.openURL, postLinkAction)
        }
    }
    private var postLinkAction: OpenURLAction {
        OpenURLAction { url in
            guard case .post(let id) = Deeplinker.getType(url: url) else {
                openURL(url)
                return .handled
            }
            if let index = viewModel.getPostIndexFromId(id) {
                replyId = index
                showReply = true
            } else {
                showPostUnavailable = true
            }
            return .handled
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
