//
//  PresentedPostDismissGesture.swift
//  swiftchan
//
//  Created by vanities on 11/26/20.
//

import SwiftUI

extension View {
    func dismissGesture(
        dismiss: Binding<Bool>,
        presenting: Binding<Bool>,
        canDrag: Binding<Bool>,
        dragging: Binding<Bool>,
        onOffsetChanged: ((CGFloat) -> Void)?) -> some View {
        self.modifier(DismissGestureModifier(
            dismiss: dismiss,
            presenting: presenting,
            canDrag: canDrag,
            dragging: dragging,
            onOffsetChanged: onOffsetChanged
        ))
    }
}

struct DismissGestureModifier: ViewModifier {
    @Binding var dismiss: Bool
    @Binding var presenting: Bool
    @Binding var canDrag: Bool
    @Binding var dragging: Bool

    @State var draggingOffset: CGFloat = UIScreen.main.bounds.height
    @State var lastDraggingValue: DragGesture.Value?
    @State var draggingVelocity: Double = 0

    var onOffsetChanged: ((CGFloat) -> Void)?

    @ViewBuilder
    func body(content: Content) -> some View {
        let drag = DragGesture(minimumDistance: 15)
            .onChanged {self.onDragChanged(with: $0)}
            .onEnded {_ in self.onDragGestureEnded()}
        content
            .offset(y: self.draggingOffset)
            .simultaneousGesture(self.canDrag ? drag : nil)
            .onChange(of: self.draggingOffset) { self.onOffsetChanged?($0) }
            .onChange(of: self.dismiss) { _ in
                withAnimation(.linear(duration: 0.25)) {
                    self.draggingOffset = UIScreen.main.bounds.height
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250)) {
                    self.presenting = false
                }
            }
            .onAppear {
                withAnimation(.linear) {
                    self.draggingOffset = .zero
                }
            }
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
                withAnimation(.linear) {
                    self.dragging = true
                }
            }

            self.draggingOffset += offsetIncrement
            self.lastDraggingValue = value
        }
    }

    func onDragGestureEnded() {
        withAnimation(.linear) {
            self.dragging = false
        }
        if self.draggingOffset > UIScreen.main.bounds.height/4 {
            self.dismiss = true
        } else {
            withAnimation(.linear) {
                self.draggingOffset = 0
                self.draggingVelocity = 0
                self.lastDraggingValue = nil
            }
        }
    }
}

extension DismissGestureModifier: Buildable {
    func onOffsetChanged(_ callback: ((CGFloat) -> Void)?) -> Self {
        mutating(keyPath: \.onOffsetChanged, value: callback)
    }
}
