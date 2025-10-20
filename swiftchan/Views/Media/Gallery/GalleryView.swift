//
//  GalleryView.swift
//  swiftchan
//
//  Created on 11/5/20.
//

import SwiftUI
import SwiftUIIntrospect
import UIKit

struct GalleryView: View {
    @AppStorage("showGalleryPreview") var showGalleryPreview = false

    @Environment(AppState.self) private var appState
    @Environment(ThreadViewModel.self) private var viewModel
    @Environment(PresentationState.self) private var state

    let index: Int

    @State private var selection: Int
    @State private var canPage = true
    @State private var canShowPreview = true
    @State private var showPreview = false
    @State private var canShowContextMenu = true
    @State private var isSeeking = false
    @State private var isZoomed = false
    @State private var pagerScrollView: UIScrollView?
    @State private var sheetPresentationController: UISheetPresentationController?

    var onMediaChanged: ((Bool) -> Void)?
    var onPageDragChanged: ((CGFloat) -> Void)?

    init(index: Int) {
        self.index = index
        _selection = State(initialValue: index)
    }

    var body: some View {
        @Bindable var state = state

        return ZStack {
            Color.black.ignoresSafeArea()

            VerticalPagerView(
                selection: $selection,
                pageCount: viewModel.media.count,
                canScroll: canPage,
                onPageChanged: { index in
                    updateActiveMedia(to: index)
                },
                onDragChanged: { translation in
                    handlePagerDragChanged(translation)
                },
                onDragEnded: {
                    handlePagerDragEnded()
                },
                onScrollViewCaptured: { scrollView in
                    guard pagerScrollView !== scrollView else { return }
                    DispatchQueue.main.async {
                        pagerScrollView = scrollView
                        scrollView.alwaysBounceVertical = true
                        scrollView.alwaysBounceHorizontal = false
                    }
                },
                content: { pageIndex in
                    mediaView(for: pageIndex)
                }
            )
            .onChange(of: state.galleryIndex) { _, newValue in
                guard selection != newValue,
                      viewModel.media.indices.contains(newValue) else { return }
                selection = newValue
                updateActiveMedia(to: newValue)
            }
            .onChange(of: viewModel.media) { _, newMedia in
                guard newMedia.indices.contains(selection) else {
                    let newIndex = max(0, min(selection, max(newMedia.count - 1, 0)))
                    if newIndex != selection {
                        selection = newIndex
                    }
                    updateActiveMedia(to: newIndex)
                    return
                }
            }
            .onAppear {
                let resolvedIndex: Int
                if viewModel.media.indices.contains(index) {
                    resolvedIndex = index
                } else {
                    resolvedIndex = max(0, min(index, max(viewModel.media.count - 1, 0)))
                }
                selection = resolvedIndex
                updateActiveMedia(to: resolvedIndex)
                isZoomed = false
                isSeeking = false
                refreshPagingState()
            }

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
            restorePagerScrolling()
            sheetPresentationController?.presentedViewController.isModalInPresentation = false
        }
        .gesture(canShowPreview && showGalleryPreview ? showPreviewTap() : nil)
        .introspect(.sheet, on: .iOS(.v17, .v18, .v26)) { controller in
            controller.prefersGrabberVisible = true
            controller.prefersScrollingExpandsWhenScrolledToEdge = false
            controller.detents = [.large()]
            sheetPresentationController = controller
            updateInteractiveDismiss(using: controller)
        }
        .statusBar(hidden: true)
    }

    @ViewBuilder
    private func mediaView(for index: Int) -> some View {
        if viewModel.media.indices.contains(index) {
            let media = viewModel.media[index]
            MediaView(media: media)
                .onMediaChanged { zoomed in
                    isZoomed = zoomed
                    refreshPagingState()
                    canShowPreview = !zoomed
                    canShowContextMenu = !zoomed
                    if zoomed {
                        showPreview = false
                    }
                    updateInteractiveDismiss()
                    onMediaChanged?(zoomed)
                }
                .onSeekChanged { seeking in
                    isSeeking = seeking
                    refreshPagingState()
                    canShowPreview = !seeking
                    canShowContextMenu = !seeking
                    updateInteractiveDismiss()
                }
                .mediaDownloadMenu(url: media.url, canShowContextMenu: $canShowContextMenu)
                .accessibilityIdentifier(
                    AccessibilityIdentifiers.galleryMediaImage(media.index)
                )
        } else {
            EmptyView()
        }
    }

    private func updateActiveMedia(to index: Int) {
        guard viewModel.media.indices.contains(index) else { return }

        onPageDragChanged?(.zero)
        canShowContextMenu = true
        isZoomed = false
        isSeeking = false
        refreshPagingState()
        state.galleryIndex = index

        if index - 1 >= 0 {
            var previousItem = viewModel.media[index - 1]
            previousItem.isSelected = false
            viewModel.media[index - 1] = previousItem
        }

        if index + 1 < viewModel.media.count {
            var nextItem = viewModel.media[index + 1]
            nextItem.isSelected = false
            viewModel.media[index + 1] = nextItem
        }

        var currentItem = viewModel.media[index]
        currentItem.isSelected = true
        viewModel.media[index] = currentItem
        updateInteractiveDismiss()

        // Dynamic prefetching: update prefetch window as user swipes
        viewModel.prefetch(currentIndex: index)
    }

    func showPreviewTap() -> some Gesture {
        TapGesture()
            .onEnded {
                withAnimation(.linear(duration: 0.2)) {
                    showPreview.toggle()
                }
            }
    }

    private func handlePagerDragChanged(_ translation: CGFloat) {
        onPageDragChanged?(translation)
    }

    private func handlePagerDragEnded() {
        onPageDragChanged?(0)
    }

    private func refreshPagingState() {
        canPage = !isZoomed && !isSeeking
    }

    private func restorePagerScrolling() {
        if let scrollView = pagerScrollView {
            if scrollView.isScrollEnabled == false {
                scrollView.isScrollEnabled = true
            }
            scrollView.panGestureRecognizer.isEnabled = true
        }
        refreshPagingState()
    }

    private func updateInteractiveDismiss(using controller: UISheetPresentationController? = nil) {
        let controller = controller ?? sheetPresentationController
        guard let controller else { return }
        let allowDismiss = !isZoomed && !isSeeking
        DispatchQueue.main.async {
            controller.presentedViewController.isModalInPresentation = !allowDismiss
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
#Preview {
    let viewModel = ThreadViewModel(boardName: "pol", id: 0)
    let urls = [
        URLExamples.image,
        URLExamples.gif,
        URLExamples.webm
    ]
    viewModel.setMedia(mediaUrls: urls, thumbnailMediaUrls: urls)

    return Group {
        GalleryView(index: 0)
            .environment(viewModel)
            .environment(PresentationState())
            .environment(AppState())
        GalleryView(index: 1)
            .environment(viewModel)
            .environment(PresentationState())
            .environment(AppState())
        GalleryView(index: 2)
            .environment(viewModel)
            .environment(PresentationState())
            .environment(AppState())
    }
}
#endif
