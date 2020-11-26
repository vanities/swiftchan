//
//  PresentedPostDismissGesture.swift
//  swiftchan
//
//  Created by vanities on 11/26/20.
//

import SwiftUI

extension View {
    func dismissGesture(presenting: Binding<Bool>,
                        canDrag: Binding<Bool>,
                        dragging: Binding<Bool>) -> some View {
        self.modifier(DismissGestureModifier(presenting: presenting,
                                             canDrag: canDrag,
                                             dragging: dragging))
    }
}

struct DismissGestureModifier: ViewModifier {
    @Binding var presenting: Bool
    @Binding var canDrag: Bool
    @Binding var dragging: Bool
    
    @GestureState var dragAmount = CGSize.zero
    @State private var offset = CGSize.zero
    
    @State var draggingOffset: CGFloat = 0
    @State var lastDraggingValue: DragGesture.Value?
    @State var draggingVelocity: Double = 0
    
    @ViewBuilder
    func body(content: Content) -> some View {
        let drag = DragGesture(minimumDistance: 15)
            .onChanged {self.onDragChanged(with: $0)}
            .onEnded {_ in self.onDragGestureEnded()}
        content
            .offset(y: self.draggingOffset)
            .simultaneousGesture(self.canDrag ? drag : nil)
    }
    
    func onDragChanged(with value: DragGesture.Value) {
        withAnimation(Animation.linear(duration: 0.01)) {
            let lastLocation = self.lastDraggingValue?.location ?? value.location
            let swipeAngle = (value.location - lastLocation).angle ?? .zero
            // Ignore swipes that aren't on the X-Axis
            guard swipeAngle.isAlongYAxis else {
                self.lastDraggingValue = value
                return
            }
            
            let offsetIncrement = (value.location.y - lastLocation.y)
            
            // If swipe hasn't started yet, ignore swipes if they didn't start on the X-Axis
            let isTranslationInYAxis = abs(value.translation.height) > abs(value.translation.width)
            guard self.draggingOffset != 0 || isTranslationInYAxis else {
                return
            }
            
            let timeIncrement = value.time.timeIntervalSince(self.lastDraggingValue?.time ?? value.time)
            if timeIncrement != 0 {
                self.draggingVelocity = Double(offsetIncrement) / timeIncrement
            }
            if !self.dragging {
                self.dragging = true
            }
            
            self.draggingOffset += offsetIncrement
            self.lastDraggingValue = value
        }
    }
    
    func onDragGestureEnded() {
        self.dragging = false
        if self.draggingOffset > UIScreen.main.bounds.height/4 {
            withAnimation(.linear) {
                self.presenting = false
            }
        } else {
            withAnimation(.linear(duration: 0.2)) {
                self.draggingOffset = 0
                self.draggingVelocity = 0
                self.lastDraggingValue = nil
            }
        }
    }
}
