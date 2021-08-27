//
//  GalleryView.swift
//  swiftchan
//
//  Created by vanities on 11/5/20.
//

import SwiftUI
import Introspect
import SwiftUIPager
import ToastUI

struct GalleryView: View {
    @EnvironmentObject var state: PresentationState
    @EnvironmentObject var dismissGesture: DismissGesture
    @StateObject var page: Page
    var urls: [URL]
    var thumbnailUrls: [URL]
    @State var canPage: Bool = true

    @State private var isExportingDocument = false

    @State var canShowPreview: Bool = true
    @State var showPreview: Bool = false
    @State var dragging: Bool = false
    @State private var presentingToast: Bool = false
    @State private var presentingToastResult: Result<URL, Error>?

    var onMediaChanged: ((Bool) -> Void)?
    var onPageDragChanged: ((CGFloat) -> Void)?
    var onDismiss: (() -> Void)?

    init(_ index: Int, urls: [URL], thumbnailUrls: [URL]) {
        self.urls = urls
        self.thumbnailUrls = thumbnailUrls
        self._page =  StateObject(wrappedValue: Page.withIndex(index))
    }

    var body: some View {
        return ZStack {
            Color.black.ignoresSafeArea()

            // gallery
            Pager(page: page,
                  data: urls.indices,
                  id: \.self) { index in
                MediaView(
                    selected: $state.galleryIndex,
                    url: urls[index],
                    id: index
                )
                .onMediaChanged { zoomed in
                    canShowPreview = !zoomed
                    canPage = !zoomed
                    if zoomed {
                        // if zooming, remove the preview
                        showPreview = !zoomed
                    }
                    onMediaChanged?(zoomed)
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.galleryMediaImage(index))
                .fileExporter(isPresented: $isExportingDocument,
                              document: FileExport(url: urls[index].absoluteString),
                              contentType: .image,
                              onCompletion: { result in
                    presentingToastResult = result
                    presentingToast = true
                })
                .contextMenu {
                    Button(action: {
                        UIPasteboard.general.string = urls[index].absoluteString
                    }, label: {
                        Text("Copy URL")
                        Image(systemName: "doc.on.doc")
                    })
                    switch MediaDetector.detect(url: urls[index]) {
                    case .image, .gif:
                        Button(action: {
                            let imageSaver = ImageSaver(completionHandler: { result in
                                presentingToast = true
                                switch result {
                                case .success(_):
                                    presentingToastResult = .success(urls[index])
                                case .failure(let error):
                                    presentingToastResult = .failure(error)
                                }
                            })
                            imageSaver.saveImageToPhotos(url: urls[index])
                        }, label: {
                            Text("Save to Photos")
                            Image(systemName: "square.and.arrow.down")
                        })
                            .accessibilityIdentifier(AccessibilityIdentifiers.saveToPhotosButton)
                    case .webm, .none:
                        Button(action: {
                            isExportingDocument.toggle()
                        }, label: {
                            Text("Save to Files")
                            Image(systemName: "folder")
                        })
                    }
                }
            }
            .onDraggingEnded {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    onPageDragChanged?(.zero)
                }
            }
            .onDraggingChanged { offset in
                DispatchQueue.main.async {
                    onPageDragChanged?(CGFloat(offset))
                }
            }
            .onPageChanged { index in
                dragging = false
                onPageDragChanged?(.zero)
                state.galleryIndex = index
            }
            .allowsDragging(!dismissGesture.dragging && canPage)
            .pagingPriority(.simultaneous)
            .swipeInteractionArea(.allAvailable)
            .background(Color.black)
            .ignoresSafeArea()

            // dismiss button
            Button(action: {
                onDismiss?()
            }, label: {
                Image(systemName: "xmark")
                    .frame(width: 50, height: 50)
                    .contentShape(Rectangle())
                    .foregroundColor(.white)
            })
            .position(x: 30, y: 10)
            .opacity(dismissGesture.dragging ? 0 : 1)

            // preview
            VStack {
                Spacer()
                GalleryPreviewView(urls: urls,
                                   thumbnailUrls: thumbnailUrls,
                                   selection: $state.galleryIndex)
                    .padding(.bottom, 60)
            }
            .opacity(showPreview && !dismissGesture.dragging ? 1 : 0)
        }
        .gesture(canShowPreview ? showPreviewTap() : nil)
        .toast(isPresented: $presentingToast, dismissAfter: 1.0) {
            switch presentingToastResult {
            case .success(_):
                ToastView("Success!", content: {}, background: {Color.clear})
                    .toastViewStyle(SuccessToastViewStyle())
                    .accessibilityIdentifier(AccessibilityIdentifiers.successToastText)
            case .failure(_):
                ToastView("Failure", content: {}, background: {Color.clear})
                    .toastViewStyle(ErrorToastViewStyle())
            case .none:
                ToastView("Failure", content: {}, background: {Color.clear})
                    .toastViewStyle(ErrorToastViewStyle())

            }
        }
        .statusBar(hidden: true)
        .onChange(of: state.galleryIndex) { index in
            page.update(.new(index: index))
        }
    }

    func showPreviewTap() -> some Gesture {
        return TapGesture(count: 1)
            .onEnded {
                withAnimation(.linear(duration: 0.2)) {
                    showPreview.toggle()
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
            GalleryView(0,
                        urls: URLExamples.imageSet,
                        thumbnailUrls: URLExamples.imageSet
            )
            .environmentObject(DismissGesture())
            GalleryView(0,
                        urls: URLExamples.gifSet,
                        thumbnailUrls: URLExamples.gifSet
            )
            .environmentObject(DismissGesture())
            GalleryView(0,
                        urls: URLExamples.webmSet,
                        thumbnailUrls: URLExamples.webmSet
            )
            .environmentObject(DismissGesture())
        }
    }
}
