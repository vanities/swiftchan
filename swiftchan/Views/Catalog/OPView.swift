//
//  OPView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI
import FourChan
import BottomSheet
import Defaults

struct OPView: View {
    @Default(.showOPPreview) var showOPPreview
    @StateObject var threadViewModel: ThreadView.ViewModel
    @EnvironmentObject var appState: AppState
    @Namespace var fullscreenNspace

    let index: Int
    let boardName: String
    let post: Post
    let comment: AttributedString

    init(index: Int, boardName: String, post: Post, comment: AttributedString) {
        self.index = index
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
                .cornerRadius(Constants.backgroundCornerRadius)
                .border(Colors.Op.border)

            NavigationLink(
                destination:
                    ThreadView()
                    .environmentObject(threadViewModel)
            ) {

                VStack(alignment: .leading, spacing: Constants.vstackSpacing) {
                    // image
                    if let url = post.getMediaUrl(boardId: boardName),
                       let thumbnailUrl = post.getMediaUrl(
                        boardId: boardName,
                        thumbnail: true
                       ) {

                        ThumbnailMediaView(
                            url: url,
                            thumbnailUrl: thumbnailUrl
                        )
                        .matchedGeometryEffect(
                            id: FullscreenModel.id,
                            in: fullscreenNspace
                        )
                        .gesture(showOPPreview ? TapGesture().onEnded {
                            withAnimation {
                                appState.setFullscreen(
                                    FullscreenModel(
                                        view: AnyView(
                                            ZStack {
                                                Color.black.ignoresSafeArea()
                                                MediaView(
                                                    media: Media(
                                                        index: 0,
                                                        url: url,
                                                        thumbnailUrl: thumbnailUrl
                                                    ),
                                                    playWebm: true
                                                )
                                            }
                                        ),
                                        nspace: fullscreenNspace
                                    )
                                )
                            }
                        } : nil)
                        .zIndex(1)
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
                                .rotationEffect(.degrees(Constants.stickyPinRotation))
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
                            .font(Constants.subjectFont)
                            .bold()
                            .lineLimit(nil)
                            .padding(.bottom, Constants.subjectPadding)

                        // comment
                        Text(comment)
                            .textSelection(.enabled)
                            .lineLimit(Constants.commentLineLimit)
                    }
                    .accessibilityIdentifier(
                        AccessibilityIdentifiers.opButton(index)
                    )
                }
                .padding(.all, Constants.padding)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .allowsHitTesting(!appState.showingCatalogMenu)
    }

    struct Constants {
        static let padding: CGFloat = 10

        static let subjectFont: Font = .system(size: 18)
        static let subjectPadding: CGFloat = 5

        static let commentLineLimit: Int = 20

        static let stickyPinRotation: CGFloat = 45

        static let vstackSpacing: CGFloat = 0

        static let backgroundCornerRadius: CGFloat = 5
    }
}

#if DEBUG
struct OPView_Previews: PreviewProvider {
    static var previews: some View {
        if let example = Post.example() {
            OPView(
                index: 0,
                boardName: "fit",
                post: example,
                comment: AttributedString("hello")
            )
        }
    }
}
#endif
