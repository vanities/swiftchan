//
//  PresentedPostDismissGesture.swift
//  swiftchan
//
//  Created by vanities on 11/26/20.
//

import SwiftUI

enum DismissDirection {
    case right, left, up, down
}

extension View {
    func dismissGesture(direction: DismissDirection) -> some View {
        self.modifier(DismissGestureModifier(
            direction: direction
        ))
    }
}

struct DismissGestureModifier: ViewModifier {
    let direction: DismissDirection
    @EnvironmentObject var dismissGesture: DismissGesture

    private let animationDuration = 0.2
    private let dismissVelocityThreshold: Double = 900
    private let dismissOffsetThreshold: CGFloat = 1/3

    @ViewBuilder
    func body(content: Content) -> some View {
        let drag = DragGesture(minimumDistance: 15, coordinateSpace: .local)
            .onChanged {self.onDragChanged(with: $0)}
            .onEnded {_ in self.onDragGestureEnded()}
        content
            .offset(
                x: [.left, .right].contains(self.direction) ? self.dismissGesture.draggingOffset : 0,
                y: [.up, .down].contains(self.direction) ? self.dismissGesture.draggingOffset : 0)
            .simultaneousGesture(self.dismissGesture.canDrag ? drag : nil)
            .onChange(of: self.dismissGesture.dismiss) { _ in
                withAnimation(.linear(duration: self.animationDuration)) {
                    self.dismissGesture.draggingOffset = self.getDismissOffset()
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + self.animationDuration) {
                    self.dismissGesture.presenting = false
                    self.dismissGesture.draggingVelocity = 0
                    self.dismissGesture.lastDraggingValue = nil
                }
            }
            .onAppear {
                withAnimation(.linear(duration: self.animationDuration)) {
                    self.dismissGesture.draggingOffset = .zero
                }
            }
    }

    func onDragChanged(with value: DragGesture.Value) {
        withAnimation(.linear) {

            let lastLocation = self.dismissGesture.lastDraggingValue?.location ?? value.location
            let swipeAngle = (value.location - lastLocation).angle ?? .zero

            switch self.direction {
            case .down, .up:
                // Ignore swipes that aren't on the Y-Axis
                guard swipeAngle.isAlongYAxis else {
                    self.dismissGesture.lastDraggingValue = value
                    return
                }

                let offsetIncrement = (value.location.y - lastLocation.y)

                // If swipe hasn't started yet, ignore swipes if they didn't start on the Y-Axis
                let isTranslationInYAxis = abs(value.translation.height) > abs(value.translation.width)
                guard self.dismissGesture.draggingOffset != 0 || isTranslationInYAxis else {
                    return
                }

                let timeIncrement = value.time.timeIntervalSince(self.dismissGesture.lastDraggingValue?.time ?? value.time)
                if timeIncrement != 0 {
                    self.dismissGesture.draggingVelocity = Double(offsetIncrement) / timeIncrement
                }
                if !self.dismissGesture.dragging {
                    self.dismissGesture.dragging = true
                }

                self.dismissGesture.draggingOffset += offsetIncrement
                self.dismissGesture.lastDraggingValue = value
                self.dismissGesture.objectWillChange.send()
            case .left, .right:
                // Ignore swipes that aren't on the X-Axis
                guard swipeAngle.isAlongXAxis else {
                    self.dismissGesture.lastDraggingValue = value
                    return
                }

                let offsetIncrement = (value.location.x - lastLocation.x)

                // If swipe hasn't started yet, ignore swipes if they didn't start on the X-Axis
                let isTranslationInXAxis = abs(value.translation.width) > abs(value.translation.height)
                guard self.dismissGesture.draggingOffset != 0 || isTranslationInXAxis else {
                    return
                }

                let timeIncrement = value.time.timeIntervalSince(self.dismissGesture.lastDraggingValue?.time ?? value.time)
                if timeIncrement != 0 {
                    self.dismissGesture.draggingVelocity = Double(offsetIncrement) / timeIncrement
                }
                if !self.dismissGesture.dragging {
                    self.dismissGesture.dragging = true
                }

                self.dismissGesture.draggingOffset += offsetIncrement
                self.dismissGesture.lastDraggingValue = value
                self.dismissGesture.objectWillChange.send()
            }

        }
    }

    func onDragGestureEnded() {
        withAnimation(.linear(duration: self.animationDuration)) {
            self.dismissGesture.dragging = false
        }
        if self.dismissedMet() {
            self.dismissGesture.dismiss = true
        } else {
            withAnimation(.linear(duration: self.animationDuration)) {
                self.dismissGesture.draggingOffset = 0
                self.dismissGesture.draggingVelocity = 0
                self.dismissGesture.lastDraggingValue = nil
            }
        }
    }

    private func dismissedMet() -> Bool {
        return self.dismissGesture.draggingOffset > self.getDismissOffset() * self.dismissOffsetThreshold ||
            self.dismissGesture.draggingVelocity > self.dismissVelocityThreshold
    }

    private func getDismissOffset() -> CGFloat {
        switch self.direction {
        case .down:
            return UIScreen.main.bounds.height
        case .up:
            return -UIScreen.main.bounds.height
        case .right:
            return UIScreen.main.bounds.width
        case .left:
            return -UIScreen.main.bounds.width
        }
    }
}
