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
    @EnvironmentObject var dismissGesture: DismissGesture
    let presentingSheet: PresentType
    @Binding var galleryIndex: Int
    let commentRepliesIndex: Int

    var onOffsetChanged: ((CGFloat) -> Void)?

    @ViewBuilder
    var body: some View {
        switch self.presentingSheet {
        case .gallery:
            GalleryView(selection: self.$galleryIndex,
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
            .dismissGesture(
                direction: .down,
                onOffsetChanged: { offset in
                    self.onOffsetChanged?(offset)
                }
            )
            .environmentObject(self.dismissGesture)
            .transition(.identity)

        case .replies:
            if let replies = self.viewModel.replies[self.commentRepliesIndex] {
                RepliesView(replies: replies,
                            commentRepliesIndex: self.commentRepliesIndex)
                    .dismissGesture(
                        direction: .right,
                        onOffsetChanged: {_ in}
                    )
                    .environmentObject(self.dismissGesture)
                    .transition(.identity)

            }
        }
    }
}

extension PresentedPost: Buildable {
    func onOffsetChanged(_ callback: ((CGFloat) -> Void)?) -> Self {
        mutating(keyPath: \.onOffsetChanged, value: callback)
    }
}

struct PresentedPost_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ThreadView.ViewModel(boardName: "g", id: 76759434)
        PresentedPost(
            presentingSheet: .gallery,
            galleryIndex: .constant(1),
            commentRepliesIndex: 0)
            .environmentObject(viewModel)
            .environmentObject(DismissGesture())
    }
}
