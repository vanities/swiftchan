//
//  ImageView.swift
//  swiftchan
//
//  Created by vanities on 11/6/20.
//

import SwiftUI
import URLImage

struct ImageView: View {
    let url: URL
    let isSelected: Bool
    let canGesture: Bool
    let minimumScale: CGFloat = 1

    let imageOptions = URLImageOptions(identifier: nil,
                                       expireAfter: 24 * 60 * 60,
                                       cachePolicy: .returnCacheElseLoad(cacheDelay: nil, downloadDelay: 0.25),
                                       maxPixelSize: CGSize(width: 5120, height: 2880))

    @State var scale: CGFloat = 1.0
    @State var zoomed: Bool = false
    @GestureState private var dragOffset = CGSize.zero
    @State private var position = CGSize.zero

    var onZoomChanged: ((Bool) -> Void)?

    var body: some View {
        return URLImage(url: url,
                        options: imageOptions) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
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
                //state = value.translation
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
        ImageView(url: URLExamples.image, isSelected: true, canGesture: true)
    }
}
