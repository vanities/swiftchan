//
//  PresentationState.swift
//  swiftchan
//
//  Created on 3/2/21.
//

import SwiftUI

@Observable
class PresentationState {
    var presentingGallery: Bool = false
    var galleryIndex: Int = 0
    var presentingIndex: Int = 0
    var presentingReplies: Bool = false
}

extension EnvironmentValues {
    /// Namespace used for the thumbnail → gallery zoom transition.
    @Entry var galleryNamespace: Namespace.ID?
    /// True for PostViews rendered inside RepliesView, so only one context
    /// registers a matchedTransitionSource for a given media index at a time.
    @Entry var inRepliesContext: Bool = false
}

extension View {
    /// Marks a thumbnail as the source of the gallery zoom transition.
    @ViewBuilder
    func galleryTransitionSource(id: Int, namespace: Namespace.ID?, isActive: Bool) -> some View {
        if let namespace, isActive {
            matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }
}
