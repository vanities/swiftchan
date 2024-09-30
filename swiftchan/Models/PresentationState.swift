//
//  PresentationState.swift
//  swiftchan
//
//  Created by vanities on 3/2/21.
//

import SwiftUI

@Observable
class PresentationState {
    var presentingGallery: Bool = false
    var galleryIndex: Int = 0
    var presentingIndex: Int = 0
    var presentingReplies: Bool = false
}
