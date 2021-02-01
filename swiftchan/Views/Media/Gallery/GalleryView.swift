//
//  GalleryView.swift
//  swiftchan
//
//  Created by vanities on 11/5/20.
//

import SwiftUI
import Introspect
import SwiftUIPager

struct GalleryView: View {
    @EnvironmentObject var dismissGesture: DismissGesture
    @Binding var selection: Int
    var urls: [URL]
    var thumbnailUrls: [URL]
    @State var canPage: Bool = true

    @State private var isExportingDocument = false

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
                MediaView(
                    selected: self.$selection,
                    url: self.urls[index],
                    id: index
                )
                    .onMediaChanged { zoomed in
                        self.canShowPreview = !zoomed
                        self.canPage = !zoomed
                        if zoomed {
                            // if zooming, remove the preview
                            self.showPreview = !zoomed
                        }
                        self.onMediaChanged?(zoomed)
                    }

                    .fileExporter(isPresented: self.$isExportingDocument,
                                  document: FileExport(url: self.urls[index].absoluteString),
                                  contentType: .image,
                                  onCompletion: { _ in })

                    .contextMenu {
                        Button(action: {
                            UIPasteboard.general.string = self.urls[index].absoluteString
                        }, label: {
                            Text("Copy URL")
                            Image(systemName: "doc.on.doc")
                        })
                        switch MediaDetector.detect(url: self.urls[index]) {
                        case .image, .gif:
                            Button(action: {
                                ImageSaver().saveImageToPhotos(url: self.urls[index])
                            }, label: {
                                Text("Save to Photos")
                                Image(systemName: "square.and.arrow.down")
                            })
                        case .webm, .none:
                            Button(action: {
                                self.isExportingDocument.toggle()
                            }, label: {
                                Text("Save to Files")
                                Image(systemName: "folder")
                            })
                        }
                    }
            }
            .onOffsetChanged { value in
                self.onPageDragChanged?(value)
            }
            .onPageChanged { _ in
                self.dragging = false
                self.onPageDragChanged?(.zero)
            }
            .allowsDragging(!self.dismissGesture.dragging && self.canPage)
            .pagingPriority(.simultaneous)
            .swipeInteractionArea(.allAvailable)
            .background(Color.black)
            .ignoresSafeArea()

            // dismiss button
            Button(action: {
                withAnimation(.linear) {
                    self.onDismiss?()
                }
            }, label: {
                Image(systemName: "xmark")
                    .frame(width: 50, height: 50)
                    .contentShape(Rectangle())
                    .foregroundColor(.white)
            })
            .position(x: 30, y: 10)
            .opacity(self.dismissGesture.dragging ? 0 : 1)

            // preview
            VStack {
                Spacer()
                GalleryPreviewView(urls: self.urls,
                                   thumbnailUrls: self.thumbnailUrls,
                                   selection: self.$selection)
                    .padding(.bottom, 60)
            }
            .opacity(self.showPreview && !self.dismissGesture.dragging ? 1 : 0)
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

extension GalleryView: Buildable {
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
                        thumbnailUrls: URLExamples.imageSet
            )
            .environmentObject(DismissGesture())
            GalleryView(selection: .constant(0),
                        urls: URLExamples.gifSet,
                        thumbnailUrls: URLExamples.gifSet
            )
            .environmentObject(DismissGesture())
            GalleryView(selection: .constant(0),
                        urls: URLExamples.webmSet,
                        thumbnailUrls: URLExamples.webmSet
            )
            .environmentObject(DismissGesture())
        }
    }
}
