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

    @State var canDrag: Bool = true
    @State var dragging: Bool = false
    @State var galleryIndex: Int

    var body: some View {
        ZStack {
            switch self.presentingSheet {
            case .gallery:
                GalleryView(selection: self.$galleryIndex,
                            urls: self.viewModel.mediaUrls,
                            thumbnailUrls: self.viewModel.thumbnailMediaUrls,
                            canPage: !self.dragging
                )
                .onDragChanged { (dragging) in
                    self.canDrag = !dragging
                }
                .onMediaChanged { (changed) in
                    self.canDrag = !changed
                    self.dragging.toggle()
                }

                Button(action: {
                    withAnimation(.linear) {
                        self.presenting = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .frame(width: 50, height: 50)
                        .contentShape(Rectangle())
                        .foregroundColor(.white)
                }
                .position(x: 20, y: 10)
            case .replies:
                if let replies = self.viewModel.replies[self.commentRepliesIndex] {
                    RepliesView(replies: replies,
                                viewModel: self.viewModel,
                                commentRepliesIndex: self.commentRepliesIndex)
                }
            }
        }
        .transition(AnyTransition.asymmetric(
                        insertion: .move(edge: .bottom),
                        removal: .move(edge: .bottom)))
        // TODO: disable dismissing when dragging to next page in gallery
        .dismissGesture(presenting: self.$presenting,
                        canDrag: self.$canDrag,
                        dragging: self.$dragging
        )
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
