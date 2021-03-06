//
//  PresentedPost.swift
//  swiftchan
//
//  Created by vanities on 11/20/20.
//

import SwiftUI

struct PresentedPost: View {
    enum PresentType {
        case gallery, replies
    }

    @EnvironmentObject var viewModel: ThreadView.ViewModel
    @EnvironmentObject var state: PresentationState
    @EnvironmentObject var dismissGesture: DismissGesture

    var onOffsetChanged: ((CGFloat) -> Void)?

    @ViewBuilder
    var body: some View {
        switch self.state.presentingSheet {
        case .gallery:
            GalleryView(
                self.state.galleryIndex,
                urls: self.viewModel.mediaUrls,
                thumbnailUrls: self.viewModel.thumbnailMediaUrls
            )
            .onDismiss {
                self.dismissGesture.dismiss = true
            }
            .onPageDragChanged { (value) in
                self.dismissGesture.canDrag = value.isZero
            }
            .onMediaChanged { (zoomed) in
                self.dismissGesture.canDrag = !zoomed
                if zoomed {
                    self.dismissGesture.dragging = false
                }
            }
            .dismissGesture(direction: .down)
            .transition(.identity)

        case .replies:
            if let replies = self.viewModel.replies[self.state.commentRepliesIndex] {
                RepliesView(replies: replies,
                            commentRepliesIndex: self.state.commentRepliesIndex)
                    .dismissGesture(direction: .right)
                    .transition(.identity)
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
