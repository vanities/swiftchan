//
//  PresentedScrollViewGesture.swift
//  swiftchan
//
//  Created by Adam Mischke on 11/11/21.
//

import SwiftUI

extension View {
    func scrollViewDismissGesture(
        namespace: Namespace.ID,
        simultaneous: Bool = true
    ) -> some View {
        self.modifier(PresentedScrollViewGestureModifier(
            namespace: namespace,
            simultaneous: simultaneous
        ))
    }
}

struct PresentedScrollViewGestureModifier: ViewModifier {
    let namespace: Namespace.ID
    let simultaneous: Bool
    @EnvironmentObject var dismissGesture: DismissGesture
    @EnvironmentObject var trackableScrollViewState: TrackableScrollViewState

    private let animationDuration = 0.2
    private let dismissVelocityThreshold: Double = 900
    private let dismissOffsetThreshold: CGFloat = 1/3
    @State var appear: Bool = false
    @State var origin: CGPoint = .zero
    @State var size: CGSize = .zero

    func body(content: Content) -> some View {
        return ZStack {
            content
                .matchedGeometryEffect(id: "1", in: namespace, properties: .frame)
                .onChange(of: dismissGesture.dismiss) {
                    dismissGesture.presenting = !$0
                }
                .onAppear {
                    origin = dismissGesture.tappedImageFrame.origin
                    origin.x = origin.x + 200
                    origin.y = origin.y + 200
                    size = dismissGesture.tappedImageFrame.size

                    withAnimation(.linear) {
                        size = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        origin = CGPoint(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height/2)
                    }
                }
        }
    }
}
