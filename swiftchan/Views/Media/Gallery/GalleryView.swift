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
    @EnvironmentObject private var viewModel: ThreadViewModel
    @EnvironmentObject private var state: PresentationState

    let index: Int

    @StateObject var page = Page.first()
    @State private var canPage = true
    @State private var canShowPreview = true
    @State private var showPreview = false
    @State private var dragging  = false
    @State private var canShowContextMenu = true

    var onMediaChanged: ((Bool) -> Void)?
    var onPageDragChanged: ((CGFloat) -> Void)?

    var body: some View {
        return ZStack {
            Color.black.ignoresSafeArea()

            // gallery
            Pager(
                page: page,
                data: viewModel.media
            ) { media in
                MediaView(media: media)
                    .onMediaChanged { zoomed in
                        canShowPreview = !zoomed
                        canPage = !zoomed
                        canShowContextMenu = !zoomed
                        if zoomed {
                            // if zooming, remove the preview
                            showPreview = !zoomed
                        }
                        onMediaChanged?(zoomed)
                    }
                    .mediaDownloadMenu(url: media.url, canShowContextMenu: $canShowContextMenu)
                    .accessibilityIdentifier(
                        AccessibilityIdentifiers.galleryMediaImage(media.index)
                    )
            }
            .onDraggingEnded {
                dragging = false
                canShowContextMenu = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    onPageDragChanged?(.zero)
                }
            }
            .onDraggingChanged {
                dragging = true
                canShowContextMenu = false
                onPageDragChanged?(CGFloat($0))
            }
            .onPageChanged { index in
                dragging = false
                canShowContextMenu = true
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
        let viewModel = ThreadViewModel(boardName: "pol", id: 0)
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
