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
    var canGesture: Bool = true
    let minimumScale: CGFloat = 1

    @State var scale: CGFloat = 1.0
    @State var zoomed: Bool = false
    @GestureState private var dragOffset = CGSize.zero
    @State private var position = CGSize.zero
    @State private var progress = Progress()

    var onZoomChanged: ((Bool) -> Void)?

    var body: some View {
        return KFImage(url)
            .placeholder {
                ProgressView(progress)
                    .progressViewStyle(WhiteCircularProgressViewStyle())
            }
            .onProgress { receivedSize, totalSize  in
                progress.completedUnitCount = receivedSize
                progress.totalUnitCount = totalSize
            }
            // .onlyFromCache()
            // .waitForCache()
            .resizable()
            .aspectRatio(contentMode: .fit)
            .offset(x: position.width + dragOffset.width, y: position.height + dragOffset.height)
            .scaleEffect(scale)
            .gesture(canGesture ? zoomMagnificationGesture() : nil)
            // allow drag, only if zoomed in or out
            .highPriorityGesture(
                zoomed && canGesture ? panDragGesture() : nil
            )
            .simultaneousGesture(canGesture ? zoomTapGesture() : nil)
            .onDisappear {
                zoomed = false
                onZoomChanged?(zoomed)
                scale = 1
                position = .zero
            }
    }

    func zoomTapGesture() -> some Gesture {
        return TapGesture(count: 2)
            .onEnded {
                // zoom in
                if scale == 1 {
                    withAnimation(.easeIn(duration: 0.2)) {
                        scale = 2
                        zoomed = true
                        onZoomChanged?(zoomed)
                    }
                }
                // zoom back
                else {
                    withAnimation(.easeOut(duration: 0.2)) {
                        scale = 1
                        position = .zero
                        zoomed = false
                        onZoomChanged?(zoomed)
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
                position.height += value.translation.height/2
                position.width += value.translation.width/2
            })
    }

    func zoomMagnificationGesture() -> some Gesture {
        return MagnificationGesture()
            .onChanged({ (value) in
                scale = value
            })
            .onEnded({ (value) in
                scale = max(value, minimumScale)
                if scale == 1 {
                   UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } else {
                    zoomed = true
                    onZoomChanged?(zoomed)
                }
            })
    }
}

extension ImageView: Buildable {
    func onZoomChanged(_ callback: ((Bool) -> Void)?) -> Self {
        mutating(keyPath: \.onZoomChanged, value: callback)
    }
}

#if DEBUG
struct ImageView_Previews: PreviewProvider {
    static var previews: some View {
        ImageView(url: URLExamples.image, canGesture: true)
    }
}
#endif
