//
//  PresentedPost.swift
//  swiftchan
//
//  Created by vanities on 11/20/20.
//

import SwiftUI

struct PresentedPost: View {
    enum PresentType {
        case gallery
    }

    @EnvironmentObject var viewModel: ThreadView.ViewModel
    @EnvironmentObject var state: PresentationState
    @EnvironmentObject var dismissGesture: DismissGesture
    @EnvironmentObject var appState: AppState

    var onOffsetChanged: ((CGFloat) -> Void)?

    @ViewBuilder
    var body: some View {
        switch state.presentingSheet {
        case .gallery:
            GalleryView(
                index: state.galleryIndex
            )
            .onDismiss {
                dismissGesture.dismiss = true
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
            .onChange(of: dismissGesture.presenting) { value in
                if !value {
                    UIApplication.shared.isIdleTimerDisabled = false // reneable this if it got disabled
                    appState.fullscreenView = nil
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

        return Group {
            PresentedPost()
                .environmentObject(viewModel)
                .environmentObject(DismissGesture())
                .environmentObject(presentationStateGallery)
        }
    }
}
#endif
