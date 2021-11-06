//
//  PresentedPost.swift
//  swiftchan
//
//  Created by vanities on 11/20/20.
//

import SwiftUI

struct PresentedPost: View {
    enum PresentType {
        case gallery, replies, reply
    }

    @EnvironmentObject var viewModel: ThreadView.ViewModel
    @EnvironmentObject var state: PresentationState
    @EnvironmentObject var dismissGesture: DismissGesture

    var onOffsetChanged: ((CGFloat) -> Void)?

    @ViewBuilder
    var body: some View {
        switch state.presentingSheet {
        case .gallery:
            GalleryView(
                state.galleryIndex
            )
            .onDismiss {
                dismissGesture.dismiss = true
                UIApplication.shared.isIdleTimerDisabled = false // reneable this if it got disabled
            }
            .onPageDragChanged { (value) in
                dismissGesture.canDrag = value.isZero
            }
            .onMediaChanged { (zoomed) in
                dismissGesture.canDrag = !zoomed
                if zoomed {
                    dismissGesture.dragging = false
                }
            }
            .dismissGesture(direction: .down)
            .transition(.identity)

        case .replies:
            if let replies = viewModel.replies[state.commentRepliesIndex] {
                RepliesView(replies: replies,
                            commentRepliesIndex: state.commentRepliesIndex)
                    .dismissGesture(direction: .right)
                    .transition(.identity)
            }
        case .reply:
            ZStack {
                Color.black
                    .opacity(0.5 - Double(dismissGesture.draggingOffset / UIScreen.main.bounds.height))
                    .ignoresSafeArea()

                ScrollView(.vertical) {
                    PostView(index: state.replyIndex)
                        .dismissGesture(
                            direction: .down,
                            minimumDuration: 0.2,
                            maximumDistance: 100,
                            simultaneous: false
                        )
                        .transition(.identity)
                        .navigationBarHidden(true)
                }
            }
        }
    }
}

#if DEBUG
struct PresentedPost_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ThreadView.ViewModel(boardName: "aco", id: 5926311)
        let presentationStateGallery = PresentationState()
        presentationStateGallery.replyIndex = 1
        presentationStateGallery.commentRepliesIndex = 1
        presentationStateGallery.presentingSheet = .gallery

        let presentationStateReply = PresentationState()
        presentationStateReply.replyIndex = 0
        presentationStateReply.presentingSheet = .reply

        let repliesViewModel = ThreadView.ViewModel(boardName: "aco", id: 5926311, replies: [0: [0, 1]])
        let presentationStateReplies = PresentationState()
        presentationStateReplies.commentRepliesIndex = 0
        presentationStateReplies.presentingSheet = .replies
        return Group {
            PresentedPost()
                .environmentObject(viewModel)
                .environmentObject(DismissGesture())
                .environmentObject(presentationStateGallery)

            PresentedPost()
                .environmentObject(viewModel)
                .environmentObject(DismissGesture())
                .environmentObject(presentationStateReply)
                .background(Color.green)

            PresentedPost()
                .environmentObject(repliesViewModel)
                .environmentObject(DismissGesture())
                .environmentObject(presentationStateReplies)
                .background(Color.red)
        }
    }
}
#endif
