//
//  PresentationState.swift
//  swiftchan
//
//  Created by vanities on 3/2/21.
//

import SwiftUI

class PresentationState: ObservableObject {
    @Published var galleryIndex: Int = 0
    @Published var commentRepliesIndex: Int = 0
    @Published var replyIndex: Int = 0
    @Published var presentingIndex: Int = 0
    @Published var presentingSheet: PresentedPost.PresentType = .gallery
}
