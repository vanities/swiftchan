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

struct ThreadView: View {
    @AppStorage("autoRefreshEnabled") private var autoRefreshEnabled = false
    @AppStorage("autoRefreshThreadTime") private var autoRefreshThreadTime = 10
    @AppStorage("hideTabOnBoards") var hideTabOnBoards = true
    @AppStorage("showRefreshProgressBar") private var showRefreshProgressBar = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppState.self) private var appState

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

    var scene: SKScene {
        let scene = SnowScene()
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        return scene
    }

    let columns = [GridItem(.flexible(), spacing: 0, alignment: .center)]

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
                                            .animation(.easeInOut(duration: 0.2), value: viewModel.currentSearchResultIndex)
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
                    }
                }
                .overlay(alignment: .bottom) {
                    if isSearching && !viewModel.searchResultIndices.isEmpty {
                        searchToolbar
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if autoRefreshEnabled && showRefreshProgressBar {
                        // Transparent spacer to reserve space for the progress bar
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 6)
                    }
                }
                .overlay {
                    if autoRefreshEnabled && showRefreshProgressBar {
                        let validatedRefreshTime = max(5, autoRefreshThreadTime > 0 ? autoRefreshThreadTime : 10)
                        VStack {
                            Spacer()
                            RefreshProgressBar(
                                progress: threadAutorefresher.autoRefreshTimer,
                                total: Double(validatedRefreshTime),
                                isPaused: threadAutorefresher.pauseAutoRefresh
                            )
                            .onTapGesture {
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                threadAutorefresher.pauseAutoRefresh.toggle()
                            }
                        }
                        .ignoresSafeArea(.all, edges: .bottom)
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
                    isPresented: $presentationState.presentingGallery,
                    onDismiss: {
                        // reneable this if it got disabled
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
                    threadAutorefresher.onRefresh = {
                        print("Thread auto refresh timer met, updating thread.")
                        Task {
                            await fetchAndPrefetchMedia(auto: true)
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
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    Task {
                        await fetchAndPrefetchMedia()
                    }
                }
                .environment(presentationState)
                .navigationTitle(viewModel.title)
                .searchable(text: $viewModel.searchText, isPresented: $isSearching)
                .onChange(of: viewModel.searchText) { _, _ in
                    viewModel.updateSearchResults()
                }
                .onChange(of: viewModel.searchFilters) { _, _ in
                    viewModel.updateSearchResults()
                }
                .toolbar(id: "toolbar-1") {
                    ToolbarItem(id: "toolbar-item-1", placement: ToolbarItemPlacement.navigationBarTrailing) {
                        Link(destination: viewModel.url) {
                            Image(systemName: "square.and.arrow.up")
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
}

extension ThreadView {
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
