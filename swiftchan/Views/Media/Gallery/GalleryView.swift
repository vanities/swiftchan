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
    var canPage: Bool = true

    @State var canShowPreview: Bool = true
    @State var showPreview: Bool = true

    var onMediaChanged: ((Bool) -> Void)?
    var onDragChanged: ((Bool) -> Void)?

    var body: some View {
        return ZStack {
            // media
            Pager(page: self.$selection, data: self.urls.indices, id: \.self) { index in
                let url = self.urls[index]
                MediaView(url: url,
                          selected: self.selection == index)
                    .onMediaChanged { change in
                        self.canShowPreview = !change
                        if change {
                            // if zooming, remove the preview
                            self.showPreview = !change
                        }
                        self.onMediaChanged?(change)
                    }
                    .tag(index)
            }
            .onOffsetChanged { value in
                if value != 0 {
                    self.onDragChanged?(true)
                }
            }
            .onPageChanged { _ in
                self.onDragChanged?(false)
            }
            .allowsDragging(self.canPage)
            .pagingPriority(.simultaneous)
            .swipeInteractionArea(.allAvailable)
            .background(Color.black)
            .ignoresSafeArea()

            // preview
            if self.showPreview {
                VStack {
                    Spacer()
                    GalleryPreviewView(urls: self.urls,
                                       thumbnailUrls: self.thumbnailUrls,
                                       selection: self.$selection)
                        .padding(.bottom, 50)
                }
                .transition(.asymmetric(insertion: .opacity, removal: .opacity))
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
}

extension GalleryView {
    func onDragChanged(_ callback: ((Bool) -> Void)?) -> Self {
        mutating(keyPath: \.onDragChanged, value: callback)
    }
}

struct GalleryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GalleryView(selection: .constant(0),
                        urls: URLExamples.imageSet,
                        thumbnailUrls: URLExamples.imageSet
            )
            GalleryView(selection: .constant(0),
                        urls: URLExamples.webmSet,
                        thumbnailUrls: URLExamples.webmSet
            )
            GalleryView(selection: .constant(0),
                        urls: URLExamples.gifSet,
                        thumbnailUrls: URLExamples.gifSet
            )
        }
    }
}
