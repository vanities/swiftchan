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
    @EnvironmentObject var viewModel: ThreadView.ViewModel
    @EnvironmentObject var state: PresentationState
    @EnvironmentObject var dismissGesture: DismissGesture

    @StateObject var page: Page

    @State private var canPage: Bool = true
    @State private var isExportingDocument = false
    @State private var canShowPreview: Bool = true
    @State private var showPreview: Bool = false
    @State private var dragging: Bool = false
    @State private var presentingToast: Bool = false
    @State private var presentingToastResult: Result<URL, Error>?
    @State private var showContextMenu: Bool = true

    var onMediaChanged: ((Bool) -> Void)?
    var onPageDragChanged: ((CGFloat) -> Void)?
    var onDismiss: (() -> Void)?

    init(_ index: Int) {
        self._page =  StateObject(wrappedValue: Page.withIndex(index))
    }

    var body: some View {
        return ZStack {
            Color.black.ignoresSafeArea()

            // gallery
            Pager(
                page: page,
                data: viewModel.media.indices,
                id: \.self
            ) { index in
                MediaView(
                    selected: $state.galleryIndex,
                    index: index
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
                                  document: FileExport(url: viewModel.media[index].url.absoluteString),
                                  contentType: .image,
                                  onCompletion: { result in
                        presentingToastResult = result
                        presentingToast = true
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    })
                    .contextMenu {
                        GalleryContextMenu(
                            url: viewModel.media[index].url,
                            isExportingDocument: $isExportingDocument,
                            showContextMenu: $showContextMenu,
                            presentingToast: $presentingToast,
                            presentingToastResult: $presentingToastResult
                        )
                    }
            }
                  .onDraggingEnded {
                      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                          onPageDragChanged?(.zero)
                      }
                  }
                  .onDraggingBegan {
                      showContextMenu = false
                  }
                  .onDraggingChanged { offset in
                      DispatchQueue.main.async {
                          onPageDragChanged?(CGFloat(offset))
                      }
                  }
                  .onDraggingEnded {
                      showContextMenu = true
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
                GalleryPreviewView(selection: $state.galleryIndex)
                    .padding(.bottom, 60)
            }
            .opacity(showPreview && !dismissGesture.dragging ? 1 : 0)
        }
        .gesture(canShowPreview ? showPreviewTap() : nil)
        .toast(isPresented: $presentingToast, dismissAfter: 1.0, content: handleToast)
        .statusBar(hidden: true)
        .onChange(of: state.galleryIndex) { index in
            page.update(.new(index: index))
        }
    }

    func showPreviewTap() -> some Gesture {
        return TapGesture()
            .onEnded {
                withAnimation(.linear(duration: 0.2)) {
                    showPreview.toggle()
                }
            }
    }

    @ViewBuilder
    func handleToast() -> some View {
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

#if DEBUG
struct GalleryView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ThreadView.ViewModel(boardName: "pol", id: 0)
        let urls = [
                URLExamples.image,
                URLExamples.gif,
                URLExamples.webm
            ]
        viewModel.setMedia(mediaUrls: urls, thumbnailMediaUrls: urls)

        return Group {
            GalleryView(0)
                .environmentObject(viewModel)
                .environmentObject(DismissGesture())
                .environmentObject(PresentationState())
            GalleryView(1)
                .environmentObject(viewModel)
                .environmentObject(DismissGesture())
                .environmentObject(PresentationState())
            GalleryView(2)
                .environmentObject(viewModel)
                .environmentObject(DismissGesture())
                .environmentObject(PresentationState())
        }
    }
}
#endif
