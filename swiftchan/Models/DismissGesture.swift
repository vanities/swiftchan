//
//  DismissGesture.swift
//  swiftchan
//
//  Created by vanities on 3/2/21.
//

import SwiftUI

class DismissGesture: ObservableObject {
    @Published var dismiss: Bool = false
    @Published var presenting: Bool = false
    @Published var canDrag: Bool = true
    @Published var dragging: Bool = false
    @Published var draggingOffset: CGFloat = UIScreen.main.bounds.height
    @Published var lastDraggingValue: DragGesture.Value?
    @Published var draggingVelocity: Double = 0
    @Published var tappedImageFrame: CGRect = .zero
}
