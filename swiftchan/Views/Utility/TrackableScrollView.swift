//
//  TrackableScrollView.swift
//  swiftchan
//
//  Created by Adam Mischke on 12/13/21.
//

import SwiftUI

@available(iOS 13.0, *)
public struct TrackableScrollView<Content>: View where Content: View {
    let axes: Axis.Set
    let showIndicators: Bool
    @Binding var contentOffset: CGFloat
    let content: Content
    @State var initialContentOffset: CGFloat = 0

    public init(_ axes: Axis.Set = .vertical, showIndicators: Bool = true, contentOffset: Binding<CGFloat>, @ViewBuilder content: () -> Content) {
        self.axes = axes
        self.showIndicators = showIndicators
        self._contentOffset = contentOffset
        self.content = content()
        self.initialContentOffset = contentOffset.wrappedValue
    }

    public var body: some View {
        GeometryReader { outsideProxy in
            ScrollView(axes, showsIndicators: showIndicators) {
                ZStack(alignment: axes == .vertical ? .top : .leading) {
                    GeometryReader { insideProxy in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self, value: [calculateContentOffset(fromOutsideProxy: outsideProxy, insideProxy: insideProxy)])
                    }
                    VStack {
                        content
                    }
                }
            }
            .onAppear {
                initialContentOffset = 0
            }
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { _ in
                DispatchQueue.main.async {
                    //contentOffset = value[0]
                }
            }
        }
    }

    private func calculateContentOffset(fromOutsideProxy outsideProxy: GeometryProxy, insideProxy: GeometryProxy) -> CGFloat {
        if axes == .vertical {
            return outsideProxy.frame(in: .global).minY - insideProxy.frame(in: .global).minY
        } else {
            return outsideProxy.frame(in: .global).minX - insideProxy.frame(in: .global).minX
        }
    }
}

@available(iOS 13.0, *)
struct ScrollOffsetPreferenceKey: PreferenceKey {
    typealias Value = [CGFloat]

    static var defaultValue: [CGFloat] = [0]

    static func reduce(value: inout [CGFloat], nextValue: () -> [CGFloat]) {
        value.append(contentsOf: nextValue())
    }
}
