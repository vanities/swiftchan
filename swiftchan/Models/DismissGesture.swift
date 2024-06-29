//
//  DismissGesture.swift
//  swiftchan
//
//  Created by vanities on 3/2/21.
//

import SwiftUI

@Observable
class DismissGesture {
    var dismiss: Bool = false
    var presenting: Bool = false
    var canDrag: Bool = true
    var dragging: Bool = false
    var draggingOffset: CGFloat = UIScreen.height
    var lastDraggingValue: DragGesture.Value?
    var draggingVelocity: Double = 0
}
