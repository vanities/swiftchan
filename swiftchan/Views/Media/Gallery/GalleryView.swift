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
import Defaults

struct GalleryView: View {
    @Default(.showGalleryPreview) var showGalleryPreview

    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var viewModel: ThreadView.ViewModel
    @EnvironmentObject private var state: PresentationState

    let index: Int

    @StateObject var page: Page = Page.first()
    @State private var canPage: Bool = true
    @State private var canShowPreview: Bool = true
    @State private var showPreview: Bool = false
    @State private var dragging: Bool = false

    var onMediaChanged: ((Bool) -> Void)?
    var onPageDragChanged: ((CGFloat) -> Void)?

    var body: some View {
        return ZStack {
            Color.black.ignoresSafeArea()

            // gallery
            Pager(
                page: page,
                data: viewModel.media,
                id: \.self
            ) { media in
                MediaView(media: media)
                    .onMediaChanged { zoomed in
                        canShowPreview = !zoomed
                        canPage = !zoomed
                        if zoomed {
                            // if zooming, remove the preview
                            showPreview = !zoomed
                        }
                        onMediaChanged?(zoomed)
                    }
                    .accessibilityIdentifier(AccessibilityIdentifiers.galleryMediaImage(media.index))
            }
            .onDraggingEnded {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    onPageDragChanged?(.zero)
                }
            }
            .onDraggingChanged {
                onPageDragChanged?(CGFloat($0))
            }
            .onPageChanged { index in
                dragging = false
                onPageDragChanged?(.zero)
                state.galleryIndex = index
                if index - 1 >= 0 {
                    viewModel.media[index - 1].isSelected = false
                }
                if index + 1 <= viewModel.media.count - 1 {
                    viewModel.media[index + 1].isSelected = false
                }
                viewModel.media[index].isSelected = true
            }
            .allowsDragging(canPage)
            .pagingPriority(.simultaneous)
            .swipeInteractionArea(.page)
            .onChange(of: state.galleryIndex) { index in
                page.update(.new(index: index))
            }
            .onAppear {
                page.update(.new(index: index))
            }

            // preview
            if showPreview {
                VStack {
                    Spacer()
                    GalleryPreviewView(selection: $state.galleryIndex)
                        .transition(.opacity)
                        .padding(.bottom, 60)
                }
            }
        }
        .onDisappear {
            appState.vlcPlayerControlModifier = nil
        }
        .gesture(canShowPreview && showGalleryPreview ? showPreviewTap() : nil)
        .statusBar(hidden: true)
    }

    func showPreviewTap() -> some Gesture {
        return TapGesture()
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
            GalleryView(index: 0)
                .environmentObject(viewModel)
                .environmentObject(DismissGesture())
                .environmentObject(PresentationState())
                .environmentObject(AppState())
            GalleryView(index: 1)
                .environmentObject(viewModel)
                .environmentObject(DismissGesture())
                .environmentObject(PresentationState())
                .environmentObject(AppState())
            GalleryView(index: 2)
                .environmentObject(viewModel)
                .environmentObject(DismissGesture())
                .environmentObject(PresentationState())
                .environmentObject(AppState())
        }
    }
}
#endif
