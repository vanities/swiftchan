//
//  PresentationState.swift
//  swiftchan
//
//  Created by vanities on 3/2/21.
//

import SwiftUI

class PresentationState: ObservableObject {
    @Published var presentingGallery: Bool = false
    @Published var galleryIndex: Int = 0
    @Published var presentingIndex: Int = 0
    @Published var presentingReplies: Bool = false
}
