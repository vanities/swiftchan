//
//  OPView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI
import FourChan
import BottomSheet

struct OPView: View {
    @StateObject var threadViewModel: ThreadView.ViewModel
    @EnvironmentObject var appState: AppState
    @Namespace var fullscreenNspace

    let boardName: String
    let post: Post
    let comment: AttributedString
    let opCommentTrailingLength: Int = 150

    init(boardName: String, post: Post, comment: AttributedString) {
        self.boardName = boardName
        self.post = post
        self.comment = comment
        self._threadViewModel = StateObject(
            wrappedValue: ThreadView.ViewModel(
                boardName: boardName,
                id: post.no
            )
        )
    }

    var body: some View {
        return ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Colors.Op.background)
                .cornerRadius(5)
                .border(Colors.Op.border)

            NavigationLink(
                destination:
                    ThreadView()
                    .environmentObject(threadViewModel)
            ) {

                VStack(alignment: .leading, spacing: 0) {
                    // image
                    if let url = post.getMediaUrl(boardId: boardName),
                       let thumbnailUrl = post.getMediaUrl(boardId: boardName, thumbnail: true) {

                        ThumbnailMediaView(
                            url: url,
                            thumbnailUrl: thumbnailUrl
                        )
                        .matchedGeometryEffect(
                            id: FullscreenModel.id,
                            in: fullscreenNspace
                        )
                            /*
                        .onTapGesture {
                            withAnimation {
                                appState.setFullscreen(
                                    FullscreenModel(
                                        view: AnyView(
                                            ImageView(url: url)
                                        ),
                                        nspace: fullscreenNspace
                                    )
                                )
                            }
                        }
                             */
                    }
                    // sticky, closed, image count, thread count
                    HStack(alignment: .center) {
                        if let replyCount = post.replies {
                            Text("R: \(replyCount)")
                                .italic()
                        }
                        if let imageCount = post.images {
                            Text("F: \(imageCount)")
                                .italic()
                        }
                        if let sticky = post.sticky,
                           sticky == 1 {
                            Image(systemName: "pin")
                                .rotationEffect(.degrees(45))
                                .foregroundColor(Colors.Op.pinColor)
                        }
                        if let closed = post.closed,
                           closed == 1 {
                            Image(systemName: "lock")
                                .foregroundColor(Colors.Op.lockColor)
                        }
                    }
                    Group {
                        // subject
                        Text(post.sub?.clean ?? "")
                            .font(.system(size: 18))
                            .bold()
                            .lineLimit(nil)
                            .padding(.bottom, 5)

                        // comment
                        Text(comment)
                            .textSelection(.enabled)
                            .lineLimit(20)
                    }
                }
                .padding(.all, 10)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .allowsHitTesting(!appState.showingCatalogMenu)
    }
}

#if DEBUG
struct OPView_Previews: PreviewProvider {
    static var previews: some View {
        if let example = Post.example() {
            OPView(boardName: "fit", post: example, comment: AttributedString("hello"))
        }
    }
}
#endif
