//
//  ImageView.swift
//  swiftchan
//
//  Created by vanities on 11/6/20.
//

import SwiftUI
import Kingfisher

struct ImageView: View {
    let url: URL
    @Binding var isSelected: Bool
    let canGesture: Bool
    let minimumScale: CGFloat = 1

    @State var scale: CGFloat = 1.0
    @State var zoomed: Bool = false
    @GestureState private var dragOffset = CGSize.zero
    @State private var position = CGSize.zero

    var onZoomChanged: ((Bool) -> Void)?

    init(url: URL, canGesture: Bool = false, isSelected: Binding<Bool> = .constant(true)) {
        self.url = url
        self.canGesture = canGesture
        self._isSelected = isSelected
    }

    var body: some View {
        return KFImage(url)
            .placeholder {
                ActivityIndicator()
            }
            .processingQueue(.mainAsync)
            // .onlyFromCache()
            // .waitForCache()

            .resizable()
            .aspectRatio(contentMode: .fit)
            .offset(x: position.width + dragOffset.width, y: position.height + dragOffset.height)
            .scaleEffect(self.scale)
            .gesture(self.canGesture ? self.zoomMagnificationGesture() : nil)
            // allow drag, only if zoomed in or out
            .highPriorityGesture(
                self.zoomed && self.canGesture ? self.panDragGesture() : nil
            )
            .simultaneousGesture(self.canGesture ? self.zoomTapGesture() : nil)
            .onChange(of: self.isSelected) { selected in
                if !selected {
                    self.zoomed = false
                    self.onZoomChanged?(self.zoomed)
                    self.scale = 1
                    self.position = .zero
                }
            }
    }

    func zoomTapGesture() -> some Gesture {
        return TapGesture(count: 2)
            .onEnded {
                // zoom in
                if self.scale == 1 {
                    withAnimation(.easeIn(duration: 0.2)) {
                        self.scale = 2
                        self.zoomed = true
                        self.onZoomChanged?(self.zoomed)
                    }
                }
                // zoom back
                else {
                    withAnimation(.easeOut(duration: 0.2)) {
                        self.scale = 1
                        self.position = .zero
                        self.zoomed = false
                        self.onZoomChanged?(self.zoomed)
                    }
                }
            }
    }

    func panDragGesture() -> some Gesture {
        return DragGesture()
            .updating($dragOffset, body: { (value, state, _) in
                // state = value.translation
                state.height = value.translation.height/2
                state.width = value.translation.width/2

            })
            .onEnded({ (value) in
                self.position.height += value.translation.height/2
                self.position.width += value.translation.width/2
            })
    }

    func zoomMagnificationGesture() -> some Gesture {
        return MagnificationGesture()
            .onChanged({ (value) in
                self.scale = value
            })
            .onEnded({ (value) in
                self.scale = max(value, self.minimumScale)
                if self.scale == 1 {
                    let vibrate = UIImpactFeedbackGenerator(style: .light)
                    vibrate.impactOccurred()
                } else {
                    self.zoomed = true
                    self.onZoomChanged?(self.zoomed)
                }
            })
    }
}

extension ImageView: Buildable {
    func onZoomChanged(_ callback: ((Bool) -> Void)?) -> Self {
        mutating(keyPath: \.onZoomChanged, value: callback)
    }
}

struct ImageView_Previews: PreviewProvider {
    static var previews: some View {
        ImageView(url: URLExamples.image, canGesture: true, isSelected: .constant(true))
    }
}
