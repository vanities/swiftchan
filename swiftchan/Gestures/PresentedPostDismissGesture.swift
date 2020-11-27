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
    func dismissGesture(
        direction: DismissDirection,
        dismiss: Binding<Bool>,
        presenting: Binding<Bool>,
        canDrag: Binding<Bool>,
        dragging: Binding<Bool>,
        onOffsetChanged: ((CGFloat) -> Void)?) -> some View {
        self.modifier(DismissGestureModifier(
            direction: direction,
            dismiss: dismiss,
            presenting: presenting,
            canDrag: canDrag,
            dragging: dragging,
            onOffsetChanged: onOffsetChanged
        ))
    }
}

struct DismissGestureModifier: ViewModifier {
    let direction: DismissDirection
    @Binding var dismiss: Bool
    @Binding var presenting: Bool
    @Binding var canDrag: Bool
    @Binding var dragging: Bool

    @State var draggingOffset: CGFloat = UIScreen.main.bounds.height
    @State var lastDraggingValue: DragGesture.Value?
    @State var draggingVelocity: Double = 0

    var onOffsetChanged: ((CGFloat) -> Void)?
    private let animationDuration = 0.2
    private let dismissVelocityThreshold: Double = 900
    private let dismissOffsetThreshold: CGFloat = 1/3

    @ViewBuilder
    func body(content: Content) -> some View {
        let drag = DragGesture(minimumDistance: 15)
            .onChanged {self.onDragChanged(with: $0)}
            .onEnded {_ in self.onDragGestureEnded()}
        content
            .offset(
                x: [.left, .right].contains(self.direction) ? self.draggingOffset : 0,
                y: [.up, .down].contains(self.direction) ? self.draggingOffset : 0)
            .simultaneousGesture(self.canDrag ? drag : nil)
            .onChange(of: self.draggingOffset) { self.onOffsetChanged?($0) }
            .onChange(of: self.dismiss) { _ in
                withAnimation(.linear(duration: self.animationDuration)) {
                    self.draggingOffset = self.getDismissOffset()
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + self.animationDuration) {
                    self.presenting = false
                }
            }
            .onAppear {
                withAnimation(.linear(duration: self.animationDuration)) {
                    self.draggingOffset = .zero
                }
            }
    }

    func onDragChanged(with value: DragGesture.Value) {
        withAnimation(Animation.linear(duration: 0.01)) {
            let lastLocation = self.lastDraggingValue?.location ?? value.location
            let swipeAngle = (value.location - lastLocation).angle ?? .zero

            switch self.direction {
            case .down, .up:
                // Ignore swipes that aren't on the Y-Axis
                guard swipeAngle.isAlongYAxis else {
                    self.lastDraggingValue = value
                    return
                }

                let offsetIncrement = (value.location.y - lastLocation.y)

                // If swipe hasn't started yet, ignore swipes if they didn't start on the Y-Axis
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
            case .left, .right:
                // Ignore swipes that aren't on the X-Axis
                guard swipeAngle.isAlongXAxis else {
                    self.lastDraggingValue = value
                    return
                }

                let offsetIncrement = (value.location.x - lastLocation.x)

                // If swipe hasn't started yet, ignore swipes if they didn't start on the X-Axis
                let isTranslationInXAxis = abs(value.translation.width) > abs(value.translation.height)
                guard self.draggingOffset != 0 || isTranslationInXAxis else {
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
    }

    func onDragGestureEnded() {
        withAnimation(.linear(duration: self.animationDuration)) {
            self.dragging = false
        }
        if self.dismissedMet() {
            self.dismiss = true
        } else {
            withAnimation(.linear(duration: self.animationDuration)) {
                self.draggingOffset = 0
                self.draggingVelocity = 0
                self.lastDraggingValue = nil
            }
        }
    }

    private func dismissedMet() -> Bool {
        return self.draggingOffset > self.getDismissOffset() * self.dismissOffsetThreshold ||
            self.draggingVelocity > self.dismissVelocityThreshold
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

extension DismissGestureModifier: Buildable {
    func onOffsetChanged(_ callback: ((CGFloat) -> Void)?) -> Self {
        mutating(keyPath: \.onOffsetChanged, value: callback)
    }
}
