import SwiftUI

struct PostDestination: Identifiable, Hashable {
    let id: Int
}

struct PostDetailView: View {
    let postID: Int
    @Environment(ThreadViewModel.self) private var model

    var body: some View {
        Group {
            if let index = model.getPostIndexFromId(String(postID)),
               !model.posts[index].isHidden(boardName: model.boardName), model.filterEffect(at: index) != .hide {
                RepliesView(replies: [index])
                    .accessibilityIdentifier("Post Detail \(postID)")
            } else {
                ContentUnavailableView("Post Unavailable", systemImage: "text.bubble",
                                       description: Text("This post is hidden or is not in the loaded thread."))
            }
        }
        .navigationTitle("#\(postID)")
        .navigationBarTitleDisplayMode(.inline)
    }
}
