//
//  RepliesView.swift
//  swiftchan
//
//  Created on 11/19/20.
//

import SwiftUI

struct RepliesView: View {
    @AppStorage("chanTheme") private var theme = ChanTheme.system
    let replies: [Int]

    let columns = [GridItem(.flexible(), spacing: 0, alignment: .center)]

    @State private var linkedPost: PostDestination?
    @State private var contextID = UUID()
    @State private var showPostUnavailable = false
    @Environment(AppState.self) private var appState

    @Environment(PresentationState.self) private var presentationState: PresentationState
    @Environment(ThreadViewModel.self) private var viewModel

    var body: some View {
        return ScrollView(.vertical, showsIndicators: true) {
            LazyVGrid(columns: columns,
                      alignment: .center,
                      spacing: 0) {
                ForEach(replies, id: \.self) { index in
                    if viewModel.posts.indices.contains(index),
                       !viewModel.posts[index].isHidden(boardName: viewModel.boardName), viewModel.filterEffect(at: index) != .hide {
                        PostView(index: index)
                    }
                }
            }
            .padding(3)
        }
        .background(theme.pageBackground)
        .environment(\.postContextID, contextID)
        .environment(\.openURL, postLinkAction)
        .onAppear {
            presentationState.activePostContext = contextID
        }
        .onDisappear {
            if !presentationState.presentingGallery, presentationState.activePostContext == contextID {
                presentationState.activePostContext = nil
            }
        }
        .alert("Post Unavailable", isPresented: $showPostUnavailable) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This post is not in the loaded thread. It may have been deleted.")
        }
        .navigationDestination(item: $linkedPost) { destination in
            PostDetailView(postID: destination.id)
                .environment(viewModel)
                .environment(presentationState)
        }
    }
    private var postLinkAction: OpenURLAction {
        OpenURLAction { url in
            guard case .post(let id) = Deeplinker.getType(url: url) else {
                return appState.openLink(url) ? .handled : .systemAction
            }
            if let index = viewModel.getPostIndexFromId(id) {
                linkedPost = PostDestination(id: viewModel.posts[index].no)
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
