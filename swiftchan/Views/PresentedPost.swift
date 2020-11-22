//
//  PresentedPost.swift
//  swiftchan
//
//  Created by vanities on 11/20/20.
//

import SwiftUI

struct PresentedPost: View {
    let presentingSheet: PresentingSheet
    let viewModel: ThreadView.ViewModel
    let commentRepliesIndex: Int

    @State var canDrag: Bool = true
    @State var galleryIndex: Int
    @Environment(\.presentationMode) var presentationMode
    @GestureState var dragAmount = CGSize.zero
    @State private var offset = CGSize.zero

    var body: some View {
        let dragGesture = DragGesture(minimumDistance: 5)
            .onChanged { gesture in
                withAnimation(.linear(duration: 0.01)) {
                    self.offset = gesture.translation
                }
            }
            .onEnded { _ in
                if self.offset.height > UIScreen.main.bounds.height/4 {
                    self.presentationMode.wrappedValue.dismiss()
                }
                withAnimation(.spring()) {
                    self.offset = .zero
                }
            }
        ZStack {
            switch self.presentingSheet {
            case .gallery:
                GalleryView(selection: self.$galleryIndex,
                            urls: self.viewModel.mediaUrls,
                            thumbnailUrls: self.viewModel.thumbnailMediaUrls
                )
                .onMediaChanged { (changed) in
                    self.canDrag = !changed
                }

                Button(action: {self.presentationMode.wrappedValue.dismiss()}) {
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
        .offset(y: self.offset.height)
        .gesture(self.canDrag ? dragGesture : nil)
    }
}

struct PresentedPost_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ThreadView.ViewModel(boardName: "fit", id: 5551578)
        PresentedPost(presentingSheet: .gallery,
                      viewModel: viewModel,
                      commentRepliesIndex: 0,
                      galleryIndex: 0)
    }
}
