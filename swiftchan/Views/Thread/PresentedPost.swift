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
                state.galleryIndex,
                urls: viewModel.mediaUrls,
                thumbnailUrls: viewModel.thumbnailMediaUrls
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
                    .opacity(1 - Double(dismissGesture.draggingOffset / UIScreen.main.bounds.height))
                    .ignoresSafeArea()
                PostView(index: state.replyIndex)
                    .dismissGesture(direction: .down)
                    .transition(.identity)
                    .scaledToFit()
                    .navigationBarHidden(true)
                    .ignoresSafeArea()
            }
        }
    }
}

struct PresentedPost_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ThreadView.ViewModel(boardName: "g", id: 76759434)
        PresentedPost()
            .environmentObject(viewModel)
            .environmentObject(DismissGesture())
            .environmentObject(PresentationState())
    }
}
