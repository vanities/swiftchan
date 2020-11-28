//
//  PresentedPost.swift
//  swiftchan
//
//  Created by vanities on 11/20/20.
//

import SwiftUI

struct PresentedPost: View {
    @Binding var presenting: Bool
    let presentingSheet: PresentingSheet
    let viewModel: ThreadView.ViewModel
    let commentRepliesIndex: Int

    @State var dismiss: Bool = false
    @State var canDrag: Bool = true
    @State var dragging: Bool = false
    @State var galleryIndex: Int

    var onOffsetChanged: ((CGFloat) -> Void)?

    var body: some View {
        ZStack {
            switch self.presentingSheet {
            case .gallery:
                GalleryView(selection: self.$galleryIndex,
                            urls: self.viewModel.mediaUrls,
                            thumbnailUrls: self.viewModel.thumbnailMediaUrls,
                            isDismissing: self.$dragging
                )
                .onDismiss {
                    self.dismiss = true
                }
                .onPageDragChanged { (value) in
                    self.canDrag = value.isZero
                }
                .onMediaChanged { (zoomed) in
                    self.canDrag = !zoomed
                    if zoomed {
                        self.dragging = false
                    }
                }
                .dismissGesture(
                    direction: .down,
                    dismiss: self.$dismiss,
                    presenting: self.$presenting,
                    canDrag: self.$canDrag,
                    dragging: self.$dragging,
                    onOffsetChanged: { offset in
                        self.onOffsetChanged?(offset)
                    }
                )
            case .replies:
                if let replies = self.viewModel.replies[self.commentRepliesIndex] {
                    RepliesView(replies: replies,
                                viewModel: self.viewModel,
                                commentRepliesIndex: self.commentRepliesIndex)
                        .dismissGesture(
                            direction: .right,
                            dismiss: self.$dismiss,
                            presenting: self.$presenting,
                            canDrag: self.$canDrag,
                            dragging: self.$dragging,
                            onOffsetChanged: {_ in}
                        )
                }
            }
        }
        .transition(.identity)
    }
}

extension PresentedPost: Buildable {
    func onOffsetChanged(_ callback: ((CGFloat) -> Void)?) -> Self {
        mutating(keyPath: \.onOffsetChanged, value: callback)
    }
}

struct PresentedPost_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ThreadView.ViewModel(boardName: "fit", id: 5551578)
        PresentedPost(
            presenting: .constant(true),
            presentingSheet: .gallery,
            viewModel: viewModel,
            commentRepliesIndex: 0,
            galleryIndex: 0)
    }
}
