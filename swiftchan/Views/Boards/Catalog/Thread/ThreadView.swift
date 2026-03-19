//
//  ThreadView.swift
//  swiftchan
//
//  Created on 10/31/20.
//

import SwiftUI
import FourChan
import Combine
import SpriteKit
import SwiftData

struct ThreadView: View {
    @AppStorage("autoRefreshEnabled") private var autoRefreshEnabled = false
    @AppStorage("autoRefreshThreadTime") private var autoRefreshThreadTime = 10
    @AppStorage("hideTabOnBoards") var hideTabOnBoards = true
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    // @Query private var allFavorites: [FavoriteThread]

    @Namespace private var galleryNamespace

    @State private var presentationState = PresentationState()
    @State private var threadAutorefresher = ThreadAutoRefresher()
    @State var viewModel: ThreadViewModel
    @State private var opacity: Double = 1
    @State private var showReply: Bool = false
    @State private var replyId: Int = 0
    @State private var showThread: Bool = false
    @State private var threadDestination = ThreadDestination(board: "", id: 0)
    @State private var showAutoRefreshToast: Bool = false
    @State private var autoRefreshToastMessage: String = ""
    @State private var isSearching: Bool = false

    // Gallery hero animation state
    @State private var galleryDragOffset: CGFloat = 0
    @State private var galleryBackgroundOpacity: Double = 1
    @State private var isGalleryZoomed: Bool = false
    @State private var isGallerySeeking: Bool = false

    @State private var scene: SKScene = {
        let s = SnowScene()
        s.scaleMode = .resizeFill
        s.backgroundColor = .clear
        return s
    }()

    let columns = [GridItem(.flexible(), spacing: 0, alignment: .center)]

    @State private var isFavorited: Bool = false

    init(boardName: String, postNumber: PostNumber) {
        self._viewModel = State(
            wrappedValue: ThreadViewModel(
                boardName: boardName,
                id: postNumber
            )
        )
    }

    @ViewBuilder
    var body: some View {
        @Bindable var appState = appState

        Group {
            switch viewModel.state {
            case .initial:
                ThreadLoadingView(viewModel: viewModel)
                    .task {
                        await viewModel.getPosts()
                    }
            case .loading:
                ThreadLoadingView(viewModel: viewModel)
            case .loaded:
                ZStack {
                    ScrollViewReader { reader in
                        ScrollView {
                            LazyVGrid(
                                columns: columns,
                                alignment: .center,
                                spacing: 0
                            ) {
                                ForEach(viewModel.posts.indices, id: \.self) { postIndex in
                                    let post = viewModel.posts[postIndex]
                                    if !post.isHidden(boardName: viewModel.boardName) && viewModel.shouldShowPost(at: postIndex) {
                                        PostView(index: postIndex)
                                            .environment(viewModel)
                                            .id(postIndex)
                                            .opacity(isSearching && !viewModel.searchResultIndices.isEmpty ?
                                                     (viewModel.searchResultIndices[viewModel.currentSearchResultIndex] == postIndex ? 1.0 : 0.5) : 1.0)
                                    }
                                }
                            }
                            .scrollTargetLayout()
                            .padding(.all, 3)
                            .onChange(of: presentationState.galleryIndex) { _, _  in
                                if !presentationState.presentingReplies && !showReply {
                                    scrollToPost(reader: reader)
                                }
                            }
                            .opacity(opacity)
                            .onChange(of: viewModel.currentSearchResultIndex) { _, _ in
                                if let postIndex = viewModel.getCurrentSearchResultPostIndex() {
                                    withAnimation {
                                        reader.scrollTo(postIndex, anchor: .center)
                                    }
                                }
                            }
                        }
                        .scrollDisabled(presentationState.presentingGallery && !presentationState.presentingReplies)
                    }

                    // Gallery hero overlay
                    if presentationState.presentingGallery && !presentationState.presentingReplies {
                        galleryOverlayContent
                            .zIndex(10)
                    }
                }
                .overlay(alignment: .bottom) {
                    if isSearching && !viewModel.searchResultIndices.isEmpty {
                        searchToolbar
                    }
                }
                .overlay {
                    if Date.isChristmas() {
                        SpriteView(scene: scene, options: [.allowsTransparency])
                            .ignoresSafeArea()
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                            .disabled(true)
                    }
                }
                .sheet(
                    isPresented: Binding(
                        get: { presentationState.presentingGallery && presentationState.presentingReplies },
                        set: { if !$0 { presentationState.presentingGallery = false } }
                    ),
                    onDismiss: {
                        UIApplication.shared.isIdleTimerDisabled = false
                    },
                    content: {
                        gallerySheetContent
                    }
                )
                .onOpenURL { url in
                    switch Deeplinker.getType(url: url) {
                    case .post(let id):
                        showReply = true
                        replyId = viewModel.getPostIndexFromId(id)
                    case .thread(let board, let id):
                        threadDestination = ThreadDestination(board: board, id: Int(id) ?? 0)
                        showThread = true
                    default:
                        break
                    }
                }
                .onAppear {
                    viewModel.prefetch()
                    refreshFavoriteState()
                    // Don't set up auto-refresh for archived threads
                    if !viewModel.isArchived {
                        threadAutorefresher.onRefresh = { [weak threadAutorefresher] in
                            print("Thread auto refresh timer met, updating thread.")
                            Task {
                                await fetchAndPrefetchMedia(auto: true)
                                threadAutorefresher?.resetTimer()
                            }
                        }
                    }
                }
                .onDisappear {
                    viewModel.stopPrefetching()
                    threadAutorefresher.cancelTimer()
                }
                .onChange(of: presentationState.presentingReplies) {
                    if presentationState.presentingReplies {
                        threadAutorefresher.cancelTimer()
                    } else {
                        threadAutorefresher.startTimer()
                    }
                }
                .refreshable {
                    // Archived threads can't be refreshed
                    guard !viewModel.isArchived else { return }
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    Task {
                        await fetchAndPrefetchMedia()
                    }
                }
                .environment(presentationState)
                .environment(\.galleryNamespace, galleryNamespace)
                .navigationTitle(viewModel.title)
                .toolbar(presentationState.presentingGallery && !presentationState.presentingReplies ? .hidden : .automatic, for: .navigationBar)
                .statusBar(hidden: presentationState.presentingGallery && !presentationState.presentingReplies)
                .searchable(text: $viewModel.searchText, isPresented: $isSearching)
                .onChange(of: viewModel.searchText) { _, _ in
                    viewModel.updateSearchResults()
                }
                .onChange(of: viewModel.searchFilters) { _, _ in
                    viewModel.updateSearchResults()
                }
                .toolbar(id: "toolbar-1") {
                    ToolbarItem(id: "toolbar-item-favorite", placement: .navigationBarTrailing) {
                        Button {
                            toggleFavorite()
                        } label: {
                            Image(systemName: isFavorited ? "heart.fill" : "heart")
                                .foregroundColor(isFavorited ? .red : .primary)
                        }
                    }
                    ToolbarItem(id: "toolbar-item-archive", placement: .navigationBarTrailing) {
                        if viewModel.isArchived {
                            Image(systemName: "archivebox.fill")
                                .foregroundColor(.orange)
                        }
                    }
                    ToolbarItem(id: "toolbar-item-1", placement: ToolbarItemPlacement.navigationBarTrailing) {
                        if viewModel.isArchived, let archiveUrl = viewModel.archiveUrl {
                            Link(destination: archiveUrl) {
                                Image(systemName: "square.and.arrow.up")
                            }
                        } else {
                            Link(destination: viewModel.url) {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                    }
                    .defaultCustomization(.hidden)
                }
                .onChange(of: showReply) {
                    if showReply {
                        threadAutorefresher.cancelTimer()
                    } else {
                        threadAutorefresher.startTimer()
                    }
                }
                .onChange(of: showThread) {
                    if showThread {
                        threadAutorefresher.cancelTimer()
                    } else {
                        threadAutorefresher.startTimer()
                    }
                }
                .navigationDestination(isPresented: $showReply) {
                    PostView(index: replyId)
                        .environment(viewModel)
                        .environment(presentationState)
                }
                .navigationDestination(isPresented: $showThread) {
                    ThreadView(boardName: threadDestination.board, postNumber: threadDestination.id)
                }
                .sheet(isPresented: $appState.showingBottomSheet) {
                    if let post = appState.selectedBottomSheetPost,
                       let index = viewModel.posts.firstIndex(of: post) {
                        Button("Hide \(index == 0 ? "Thread" : "Post")") {
                            post.hide(boardName: viewModel.boardName)
                        }
                        .presentationDetents([.fraction(0.1)])
                    }
                }
                .toolbar(hideTabOnBoards ? .hidden : .automatic, for: .tabBar)
            case .error:
                let _ = print("DEBUG View: errorType=\(viewModel.errorType), canLoadFromArchive=\(viewModel.canLoadFromArchive), board=\(viewModel.boardName)")
                VStack(spacing: 20) {
                    // Retry button
                    VStack {
                        Image(systemName: "arrow.clockwise")
                            .frame(width: 25, height: 25)
                        Text("Error loading thread, Tap to retry.")
                    }
                    .onTapGesture {
                        Task {
                            await viewModel.getPosts()
                        }
                    }
                    .foregroundColor(Color.red)

                    // Archive option - only show for not found errors on supported boards
                    if viewModel.errorType == .notFound && viewModel.canLoadFromArchive {
                        Divider()
                            .padding(.horizontal, 50)

                        VStack {
                            Image(systemName: "archivebox")
                                .frame(width: 25, height: 25)
                            Text("Thread may be archived.\nTap to load from 4plebs.")
                                .multilineTextAlignment(.center)
                        }
                        .onTapGesture {
                            Task {
                                await viewModel.loadFromArchive()
                            }
                        }
                        .foregroundColor(Color.orange)
                    }
                }
                .padding()
            }
        }
        .toast(isPresented: $showAutoRefreshToast, dismissAfter: 1.5) {
            ToastView(autoRefreshToastMessage, content: {}, background: { Color.clear })
                .toastViewStyle(ErrorToastViewStyle())
        }
    }

    @ViewBuilder
    var searchToolbar: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        label: "Has Media",
                        isSelected: viewModel.searchFilters.hasMedia,
                        action: {
                            viewModel.searchFilters.hasMedia.toggle()
                        }
                    )

                    FilterChip(
                        label: "Has Replies",
                        isSelected: viewModel.searchFilters.hasReplies,
                        action: {
                            viewModel.searchFilters.hasReplies.toggle()
                        }
                    )
                }
                .padding(.horizontal)
            }

            HStack {
                Text("\(viewModel.currentSearchResultIndex + 1) of \(viewModel.searchResultIndices.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    viewModel.jumpToPreviousSearchResult()
                }) {
                    Image(systemName: "chevron.up")
                        .padding(8)
                }
                .disabled(viewModel.searchResultIndices.isEmpty)

                Button(action: {
                    viewModel.jumpToNextSearchResult()
                }) {
                    Image(systemName: "chevron.down")
                        .padding(8)
                }
                .disabled(viewModel.searchResultIndices.isEmpty)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(.regularMaterial)
    }

    private func fetchAndPrefetchMedia(auto: Bool = false) async {
        let hadPosts = !viewModel.posts.isEmpty
        await viewModel.getPosts()
        if viewModel.state == .loaded {
            viewModel.prefetch()
        } else if auto {
            autoRefreshToastMessage = hadPosts ? "Could not auto refresh" : "Thread not found"
            showAutoRefreshToast = true
        }
    }

    private func scrollToPost(reader: ScrollViewProxy) {
        if presentationState.presentingIndex != presentationState.galleryIndex,
           let mediaI = viewModel.postMediaMapping.firstIndex(where: { $0.value == presentationState.galleryIndex }) {
            reader.scrollTo(viewModel.postMediaMapping[mediaI].key, anchor: viewModel.media.count - presentationState.galleryIndex < 3 ? .bottom : .top)
        }
    }

    private func refreshFavoriteState() {
        let threadId = viewModel.id
        let boardName = viewModel.boardName
        var descriptor = FetchDescriptor<FavoriteThread>(
            predicate: #Predicate { $0.threadId == threadId && $0.boardName == boardName }
        )
        descriptor.fetchLimit = 1
        isFavorited = ((try? modelContext.fetchCount(descriptor)) ?? 0) > 0
    }

    private func toggleFavorite() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        let threadId = viewModel.id
        let boardName = viewModel.boardName
        var descriptor = FetchDescriptor<FavoriteThread>(
            predicate: #Predicate { $0.threadId == threadId && $0.boardName == boardName }
        )
        descriptor.fetchLimit = 1
        let matches = (try? modelContext.fetch(descriptor)) ?? []

        if let existingFavorite = matches.first {
            modelContext.delete(existingFavorite)
        } else {
            guard let firstPost = viewModel.posts.first else { return }

            let favorite = FavoriteThread(
                threadId: viewModel.id,
                boardName: viewModel.boardName,
                title: firstPost.sub?.clean ?? "",
                thumbnailUrlString: firstPost.getMediaUrl(boardId: viewModel.boardName, thumbnail: true)?.absoluteString,
                replyCount: firstPost.replies ?? 0,
                imageCount: firstPost.images ?? 0,
                createdTime: Date(timeIntervalSince1970: TimeInterval(firstPost.time ?? 0))
            )
            modelContext.insert(favorite)
        }
        refreshFavoriteState()
    }
}

extension ThreadView {
    // MARK: - Gallery Hero Overlay

    @ViewBuilder
    private var galleryOverlayContent: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
                .opacity(galleryBackgroundOpacity)

            GalleryView(index: presentationState.galleryIndex)
                .onMediaChanged { zoomed in
                    isGalleryZoomed = zoomed
                }
                .onSeekChanged { seeking in
                    isGallerySeeking = seeking
                }
                .onDismissDrag { translation in
                    galleryDragOffset = translation
                    let progress = min(translation / 300, 1)
                    galleryBackgroundOpacity = 1 - (progress * 0.6)
                }
                .onDismissDragEnded { velocity in
                    // Rubber-banded offset is small (~30-50pt for big drags), so use low threshold
                    // velocity.y < 0 means user was dragging content offset downward (finger moving down)
                    let offsetThreshold: CGFloat = 20
                    let velocityThreshold: CGFloat = 0.3
                    if galleryDragOffset > offsetThreshold || velocity < -velocityThreshold {
                        dismissGallery()
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            galleryDragOffset = 0
                            galleryBackgroundOpacity = 1
                        }
                    }
                }
                .onClosePressed {
                    dismissGallery()
                }
                .environment(appState)
                .environment(presentationState)
                .environment(viewModel)
                .matchedGeometryEffect(
                    id: "gallery-\(presentationState.galleryIndex)",
                    in: galleryNamespace,
                    isSource: true
                )
                .offset(y: galleryDragOffset)
                .scaleEffect(galleryDragScale)
                .onAppear {
                    threadAutorefresher.cancelTimer()
                }
                .onDisappear {
                    threadAutorefresher.startTimer()
                }
        }
        .transition(.opacity)
    }

    private var galleryDragScale: CGFloat {
        let progress = min(abs(galleryDragOffset) / 300, 1)
        return 1 - (progress * 0.3)
    }

    private func dismissGallery() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            presentationState.presentingGallery = false
            galleryDragOffset = 0
            galleryBackgroundOpacity = 1
        }
        UIApplication.shared.isIdleTimerDisabled = false
    }

    // MARK: - Gallery Sheet (fallback for replies context)

    @ViewBuilder
    private var gallerySheetContent: some View {
        let gallery = GalleryView(
            index: presentationState.galleryIndex
        )
        .environment(appState)
        .environment(presentationState)
        .environment(viewModel)
        .onAppear {
            threadAutorefresher.cancelTimer()
        }
        .onDisappear {
            threadAutorefresher.startTimer()
        }

        if #available(iOS 16.0, *) {
            gallery
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        } else {
            gallery
        }
    }
}

struct ThreadLoadingView: View {
    let viewModel: ThreadViewModel

    var body: some View {
        VStack(spacing: 15) {
            Text("Loading Thread")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text(viewModel.progressText.isEmpty ? "Preparing..." : viewModel.progressText)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                .scaleEffect(1.5, anchor: .center)
        }
        .padding()
    }
}

#if DEBUG
#Preview {
    NavigationView {
        ThreadView(boardName: "biz", postNumber: 60278989)
            .environment(AppState())
    }
}
#endif
