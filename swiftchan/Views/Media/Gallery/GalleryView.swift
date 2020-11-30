//
//  GalleryView.swift
//  swiftchan
//
//  Created by vanities on 11/5/20.
//

import SwiftUI
import Introspect
import SwiftUIPager

struct GalleryView: View, Buildable {
    @Binding var selection: Int
    var urls: [URL]
    var thumbnailUrls: [URL]
    @State var canPage: Bool = true
    @Binding var isDismissing: Bool

    @State var mediaStates: [MediaState] = Array(repeating: .pause, count: 100)
    @State var canShowPreview: Bool = true
    @State var showPreview: Bool = false
    @State var dragging: Bool = false

    var onMediaChanged: ((Bool) -> Void)?
    var onPageDragChanged: ((CGFloat) -> Void)?
    var onDismiss: (() -> Void)?

    var body: some View {
        return ZStack {
            Color.black.ignoresSafeArea()

            // gallery
            Pager(page: self.$selection, data: self.urls.indices, id: \.self) { index in
                let url = self.urls[index]
                MediaView(url: url,
                          selected: self.selection == index,
                          mediaState: self.$mediaStates[index])
                    .onMediaChanged { zoomed in
                        self.canShowPreview = !zoomed
                        self.canPage = !zoomed
                        if zoomed {
                            // if zooming, remove the preview
                            self.showPreview = !zoomed
                        }
                        self.onMediaChanged?(zoomed)
                    }
            }
            .onOffsetChanged { value in
                self.onPageDragChanged?(value)
            }
            .onPageChanged { pageIndex in
                print("change page to", self.selection)
                self.dragging = false
                self.onPageDragChanged?(.zero)

                for i in mediaStates.indices {
                    if i != pageIndex {
                        self.mediaStates[i] = .pause
                    }
                }
                self.mediaStates[pageIndex] = .play
            }
            .allowsDragging(!self.isDismissing && self.canPage)
            .pagingPriority(.simultaneous)
            .swipeInteractionArea(.allAvailable)
            .background(Color.black)
            .ignoresSafeArea()

            // dismiss button
            if !self.isDismissing {
                Button(action: {
                    withAnimation(.linear) {
                        self.onDismiss?()
                    }
                }) {
                    Image(systemName: "xmark")
                        .frame(width: 50, height: 50)
                        .contentShape(Rectangle())
                        .foregroundColor(.white)
                }
                .transition(.opacity)
                .position(x: 30, y: 10)

            }

            // preview
            if self.showPreview && !self.isDismissing {
                VStack {
                    Spacer()
                    GalleryPreviewView(urls: self.urls,
                                       thumbnailUrls: self.thumbnailUrls,
                                       selection: self.$selection)
                        .padding(.bottom, 60)
                }
                .transition(.opacity)
            }
        }
        .gesture(self.canShowPreview ? self.showPreviewTap() : nil)
    }

    func showPreviewTap() -> some Gesture {
        return TapGesture(count: 1)
            .onEnded {
                withAnimation(.linear(duration: 0.2)) {
                    self.showPreview.toggle()
                }
            }
    }

}

extension GalleryView {
    func onMediaChanged(_ callback: ((Bool) -> Void)?) -> Self {
        mutating(keyPath: \.onMediaChanged, value: callback)
    }
    func onPageDragChanged(_ callback: ((CGFloat) -> Void)?) -> Self {
        mutating(keyPath: \.onPageDragChanged, value: callback)
    }
    func onDismiss(_ callback: (() -> Void)?) -> Self {
        mutating(keyPath: \.onDismiss, value: callback)
    }
}

struct GalleryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GalleryView(selection: .constant(0),
                        urls: URLExamples.imageSet,
                        thumbnailUrls: URLExamples.imageSet,
                        isDismissing: .constant(false)
            )
            GalleryView(selection: .constant(0),
                        urls: URLExamples.webmSet,
                        thumbnailUrls: URLExamples.webmSet,
                        isDismissing: .constant(false)
            )
            GalleryView(selection: .constant(0),
                        urls: URLExamples.gifSet,
                        thumbnailUrls: URLExamples.gifSet,
                        isDismissing: .constant(false)
            )
        }
    }
}
