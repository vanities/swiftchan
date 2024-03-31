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
    @State var threadViewModel: ThreadViewModel
    @EnvironmentObject var appState: AppState
    @Namespace var fullscreenNspace

    let index: Int
    let boardName: String
    let post: Post
    let swiftchanPost: SwiftchanPost
    let comment: AttributedString

    init(boardName: String, post: SwiftchanPost) {
        self.boardName = boardName
        self.post = post.post
        self.swiftchanPost = post
        self.comment = post.comment
        self.index = post.index
        self._threadViewModel = State(
            wrappedValue: ThreadViewModel(
                boardName: boardName,
                id: post.post.no
            )
        )
    }

    var body: some View {
        return ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Colors.Op.background)
                .cornerRadius(Constants.backgroundCornerRadius)
                .border(Colors.Op.border)

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
                            id: FullscreenModal.id,
                            in: fullscreenNspace
                        )
                        .gesture(showOPPreview ? TapGesture().onEnded {
                            withAnimation {
                                appState.setFullscreen(
                                    FullscreenModal(
                                        view: AnyView(
                                            ZStack {
                                                Color.black.ignoresSafeArea()
                                                MediaView(
                                                    media: Media(
                                                        index: 0,
                                                        url: url,
                                                        thumbnailUrl: thumbnailUrl
                                                    )
                                                )
                                            }
                                        ),
                                        nspace: fullscreenNspace
                                    )
                                )
                            }
                        } : nil)
                        .zIndex(1)
                        .overlay {
                            if Date.isFourchanBday() {
                                Image("PartyHat")
                                    .resizable()
                                    .frame(width: 125, height: 125)
                                    .position(x: 45, y: -25)
                            }
                            if Date.isChristmas() {
                                Image("SantaHat")
                                    .resizable()
                                    .frame(width: 125, height: 125)
                                    .position(x: 45, y: -25)
                            }
                        }

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
        .environment(threadViewModel)
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
            let swiftchanPost = SwiftchanPost(
                post: example,
                boardName: "fit",
                comment: AttributedString("hello"),
                index: 0
            )
            OPView(
                boardName: "fit",
                post: swiftchanPost
            )
        }
    }
}
#endif
