//
//  ImageView.swift
//  swiftchan
//
//  Created by vanities on 11/6/20.
//

import SwiftUI
import URLImage

struct ImageView: View, Buildable {
    let url: URL
    let isSelected: Bool
    let canResize: Bool
    let minimumScale: CGFloat = 0.75

    let imageOptions = URLImageOptions(identifier: nil,
                                       expireAfter: 24 * 60 * 60,
                                       cachePolicy: .returnCacheElseLoad(cacheDelay: nil, downloadDelay: 0.25),
                                       maxPixelSize: CGSize(width: 5120, height: 2880))

    @State var scale: CGFloat = 1.0
    @State var zoomed: Bool = false
    @GestureState private var dragOffset = CGSize.zero
    @State private var position = CGSize.zero

    func onZoomChanged(_ callback: ((Bool) -> Void)?) -> Self {
        mutating(keyPath: \.onZoomChanged, value: callback)
    }
    var onZoomChanged: ((Bool) -> Void)?

    var body: some View {
        let tapZoomGesture = TapGesture(count: 2)
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
        
        let dragGesture = DragGesture()
                           .updating($dragOffset, body: { (value, state, transaction) in

                               state = value.translation
                           })
            .onEnded({ (value) in
                self.position.height += value.translation.height
                self.position.width += value.translation.width
            })

        let pinchZoomGesture = MagnificationGesture()
            .onChanged({ (value) in
                self.scale = value
            })
            .onEnded({ (value) in
                self.scale = value
                if self.scale != 1 {
                    self.zoomed = true
                    self.onZoomChanged?(self.zoomed)
                }
            })

        return URLImage(url: url,
                        options: imageOptions) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
        .offset(x: position.width + dragOffset.width, y: position.height + dragOffset.height)
        .scaleEffect(max(self.scale, self.minimumScale))
        .gesture(self.canResize ? pinchZoomGesture : nil)
        // allow drag, only if zoomed in or out
        .highPriorityGesture(
            self.zoomed && self.canResize ? dragGesture : nil
        )
        .simultaneousGesture(self.canResize ? tapZoomGesture : nil)
        .onChange(of: self.isSelected) { selected in
            if !selected {
                self.zoomed = false
                self.onZoomChanged?(self.zoomed)
                self.scale = 1
                self.position = .zero
            }
        }
    }
}

struct ImageView_Previews: PreviewProvider {
    static var previews: some View {
        ImageView(url: URLExamples.image, isSelected: true, canResize: true)
    }
}
