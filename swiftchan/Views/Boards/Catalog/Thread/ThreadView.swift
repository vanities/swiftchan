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
    @AppStorage("chanTheme") private var theme = ChanTheme.system
    @AppStorage("autoRefreshEnabled") private var autoRefreshEnabled = false
    @AppStorage("autoRefreshThreadTime") private var autoRefreshThreadTime = 10
    @AppStorage("hideTabOnBoards") var hideTabOnBoards = true
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var followedGenerals: [RecurringFavorite]
    @Query private var savedReplies: [SavedReply]
    @State private var bookmarkError: String?

    @State private var presentationState = PresentationState()
    @State private var threadAutorefresher = ThreadAutoRefresher()
    @State var viewModel: ThreadViewModel
    @State private var opacity: Double = 1
    @State private var linkedPost: PostDestination?
    @State private var replyReturnPostID: Int?
    @State private var showPostUnavailable = false
    @AppStorage("rememberThreadPositions") private var rememberThreadPositions = true
    @State private var reading = ThreadReadingSession()
    @State private var visiblePostIDs: [Int] = []
    @State private var showFollowGeneral = false
    @State private var rolloverGeneral: RecurringFavorite?
    @State private var nextGeneral: ThreadDestination?
    @State private var draftPost: DraftPost?
    @State private var recentlyHidden: HiddenPost?
    private let initialPostID: Int?
    private let showsNavigationTitle: Bool
    @State private var isThreadVisible = false
    @State private var isSearching: Bool = false
    @Namespace private var galleryNamespace

    @State private var scene: SKScene = {
        let s = SnowScene()
        s.scaleMode = .resizeFill
        s.backgroundColor = .clear
        return s
    }()

    let columns = [GridItem(.flexible(), spacing: 0, alignment: .center)]

    @State private var isFavorited: Bool = false

    init(boardName: String, postNumber: PostNumber, postID: Int? = nil, showsNavigationTitle: Bool = true) {
        initialPostID = postID
        self.showsNavigationTitle = showsNavigationTitle
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
            case .initial, .loading:
                ThreadLoadingView(viewModel: viewModel)
                    .task {
                        if viewModel.state == .initial {
                            await viewModel.getPosts()
                        }
                    }
            case .loaded:
                let newPostID = reading.firstNewPostID(in: readablePostIDs)
                ZStack {
                    ScrollViewReader { reader in
                        ScrollView {
                            LazyVGrid(
                                columns: columns,
                                alignment: .center,
                                spacing: 0
                            ) {
                                ForEach(Array(viewModel.posts.enumerated()), id: \.element.no) { postIndex, post in
                                    if !post.isHidden(boardName: viewModel.boardName), viewModel.filterEffect(at: postIndex) != .hide,
                                       viewModel.shouldShowPost(at: postIndex) {
                                        VStack(spacing: 0) {
                                            if rememberThreadPositions, post.no == newPostID {
                                                Text("New replies")
                                                    .font(.caption.bold())
                                                    .foregroundStyle(.tint)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(8)
                                                    .background(.tint.opacity(0.1))
                                                    .accessibilityIdentifier("New Replies Divider")
                                            }
                                            PostView(index: postIndex)
                                                .environment(viewModel)
                                        }
                                            .id(post.no)
                                            .opacity(isSearching && !viewModel.searchResultIndices.isEmpty ?
                                                     (viewModel.searchResultIndices[viewModel.currentSearchResultIndex] == postIndex ? 1.0 : 0.5) : 1.0)
                                    }
                                }
                            }
                            .scrollTargetLayout()
                            .padding(.all, 3)
                            .task {
                                guard !reading.started else { return }
                                let saved = rememberThreadPositions ? ThreadReadingStore.shared.progress(board: viewModel.boardName, threadID: viewModel.id) : nil
                                let linkedPost = initialPostID.flatMap { readablePostIDs.contains($0) ? $0 : nil }
                                if initialPostID != nil && linkedPost == nil { showPostUnavailable = true }
                                let target = reading.start(postIDs: readablePostIDs, saved: saved, linkedPostID: linkedPost)
                                await Task.yield()
                                if let target { reader.scrollTo(target, anchor: .top) }
                                recordVisiblePosts()
                            }
                            .onChange(of: presentationState.galleryIndex) { _, _  in
                                if !presentationState.presentingReplies && linkedPost == nil {
                                    scrollToPost(reader: reader)
                                }
                            }
                            .opacity(opacity)
                            .onChange(of: viewModel.currentSearchResultIndex) { _, _ in
                                if let postIndex = viewModel.getCurrentSearchResultPostIndex() {
                                    withAnimation {
                                        reader.scrollTo(viewModel.posts[postIndex].no, anchor: .center)
                                    }
                                }
                            }
                        }
                        .accessibilityIdentifier("Thread Posts")
                        .task(id: linkedPost) {
                            if linkedPost == nil, let postID = replyReturnPostID {
                                // Restore the reading anchor after navigation and gallery layout changes.
                                await Task.yield()
                                reader.scrollTo(postID, anchor: .top)
                                replyReturnPostID = nil
                            }
                        }
                        .onScrollTargetVisibilityChange(idType: Int.self, threshold: 0.1) { ids in
                            visiblePostIDs = ids
                            recordVisiblePosts()
                        }
                        .onScrollPhaseChange { _, phase in
                            if phase == .idle { ThreadReadingStore.shared.flush() }
                        }
                        .safeAreaInset(edge: .bottom, spacing: 0) {
                            if !isSearching, viewModel.searchText.isEmpty, viewModel.searchFilters == SearchFilters(),
                               readablePostIDs.count > 1 {
                                HStack {
                                    Spacer()
                                    Menu {
                                        if rememberThreadPositions, let firstUnread = unreadPostIDs.first {
                                            Button("\(unreadPostIDs.count) Unread \(unreadPostIDs.count == 1 ? "Reply" : "Replies")", systemImage: "arrow.down") {
                                                reader.scrollTo(firstUnread, anchor: .top)
                                            }
                                            .accessibilityIdentifier("Jump To Unread")
                                        }
                                        Button("First Post", systemImage: "arrow.up.to.line") {
                                            if let first = readablePostIDs.first { reader.scrollTo(first, anchor: .top) }
                                        }
                                        .accessibilityIdentifier("Jump To First Post")
                                        Button("Latest Reply", systemImage: "arrow.down.to.line") {
                                            if let last = readablePostIDs.last { reader.scrollTo(last, anchor: .bottom) }
                                        }
                                        .accessibilityIdentifier("Jump To Latest Reply")
                                    } label: {
                                        Label("Jump", systemImage: "arrow.up.arrow.down")
                                            .font(.subheadline.weight(.semibold))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(.regularMaterial, in: Capsule())
                                    }
                                    .accessibilityLabel("Jump within thread")
                                    .accessibilityIdentifier("Thread Jump Menu")
                                    .padding(12)
                                }
                            }
                        }
                    }
                }
                .overlay(alignment: .bottom) {
                    if isSearching && !viewModel.searchResultIndices.isEmpty {
                        searchToolbar
                    } else if viewModel.searchFilters.posterID != nil {
                        posterIDFilterBanner
                    }
                }
                .safeAreaInset(edge: .top) {
                    if let error = viewModel.refreshError {
                        Text(error)
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(.regularMaterial)
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
                .fullScreenCover(
                    isPresented: $presentationState.presentingGallery,
                    onDismiss: {
                        // reneable this if it got disabled
                        UIApplication.shared.isIdleTimerDisabled = false
                        // Deselect all media so no video is left flagged as
                        // playing after the gallery closes.
                        for index in viewModel.media.indices where viewModel.media[index].isSelected {
                            viewModel.media[index].isSelected = false
                        }
                    },
                    content: {
                        gallerySheetContent
                            // Zoom back to whichever media the user is on;
                            // scrollToPost keeps its thumbnail on screen.
                            .navigationTransition(
                                .zoom(sourceID: presentationState.galleryIndex, in: galleryNamespace)
                            )
                    }
                )
                .environment(\.openURL, postLinkAction)
                .alert("Post Unavailable", isPresented: $showPostUnavailable) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("This post is not in the loaded thread. It may have been deleted.")
                }
                .onAppear {
                    isThreadVisible = true
                    viewModel.prefetch()
                    refreshFavoriteState()
                    recordVisiblePosts()
                    threadAutorefresher.onRefresh = { [weak threadAutorefresher] in
                        Task {
                            await fetchAndPrefetchMedia()
                            threadAutorefresher?.resetTimer()
                        }
                    }
                    updateAutoRefreshState()
                }
                .onDisappear {
                    isThreadVisible = false
                    ThreadReadingStore.shared.flush()
                    viewModel.stopPrefetching()
                    threadAutorefresher.cancelTimer()
                }
                .onChange(of: scenePhase) {
                    updateAutoRefreshState()
                    if scenePhase != .active { ThreadReadingStore.shared.flush() }
                }
                .onChange(of: ThreadReadingStore.shared.resetID) {
                    reading = ThreadReadingSession()
                    _ = reading.start(postIDs: readablePostIDs, saved: nil, linkedPostID: nil)
                }
                .onChange(of: viewModel.isArchived) { updateAutoRefreshState() }
                .onChange(of: presentationState.presentingGallery) { updateAutoRefreshState() }
                .onChange(of: autoRefreshEnabled) { updateAutoRefreshState() }
                .onChange(of: autoRefreshThreadTime) { updateAutoRefreshState() }
                .onChange(of: presentationState.presentingReplies) {
                    if presentationState.presentingReplies {
                        if replyReturnPostID == nil {
                            replyReturnPostID = reading.postID ?? visiblePostIDs.min()
                        }
                        threadAutorefresher.cancelTimer()
                    } else {
                        updateAutoRefreshState()
                    }
                }
                .refreshable {
                    // Archived threads can't be refreshed
                    guard !viewModel.isArchived else { return }
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    await fetchAndPrefetchMedia()
                }
                .environment(presentationState)
                .environment(\.galleryNamespace, galleryNamespace)
                .navigationTitle(showsNavigationTitle ? viewModel.title : "")
                .searchable(text: $viewModel.searchText, isPresented: $isSearching)
                .onChange(of: viewModel.searchText) { _, _ in
                    viewModel.updateSearchResults()
                }
                .onChange(of: viewModel.searchFilters) { _, _ in
                    viewModel.updateSearchResults()
                }
                .onChange(of: PostFilterStore.shared.rules) { viewModel.updateSearchResults() }
                .sheet(isPresented: $showFollowGeneral) {
                    if let suggestion = GeneralSuggestion(title: viewModel.title) {
                        AddRecurringFavoriteSheet(searchPattern: suggestion.tag, boardName: viewModel.boardName,
                                                 displayName: suggestion.name, favorite: followedGeneral)
                    }
                }
                .toolbar(id: "toolbar-1") {
                    ToolbarItem(id: "toolbar-follow-general", placement: .navigationBarTrailing) {
                        if GeneralSuggestion(title: viewModel.title) != nil {
                            Button {
                                showFollowGeneral = true
                            } label: {
                                Image(systemName: followedGeneral == nil ? "repeat" : "repeat.circle.fill")
                            }
                            .accessibilityLabel(followedGeneral == nil ? "Follow this general" : "Edit followed general")
                            .accessibilityIdentifier("Follow This General")
                        }
                    }
                    ToolbarItem(id: "toolbar-item-favorite", placement: .navigationBarTrailing) {
                        Button {
                            toggleFavorite()
                        } label: {
                            Image(systemName: isFavorited ? "heart.fill" : "heart")
                                .foregroundColor(isFavorited ? .red : .primary)
                        }
                        .accessibilityLabel(isFavorited ? "Remove Saved Thread" : "Save Thread")
                        .accessibilityIdentifier("Toggle Thread Favorite")
                    }
                    ToolbarItem(id: "toolbar-item-archive", placement: .navigationBarTrailing) {
                        if viewModel.isArchived {
                            Image(systemName: "archivebox.fill")
                                .foregroundColor(.orange)
                        }
                    }
                    ToolbarItem(id: "toolbar-item-1", placement: ToolbarItemPlacement.navigationBarTrailing) {
                        if viewModel.isArchived, let archiveUrl = viewModel.archiveUrl {
                            ShareLink(item: archiveUrl) {
                                Image(systemName: "square.and.arrow.up")
                            }
                        } else {
                            ShareLink(item: viewModel.url) {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                    }
                    .defaultCustomization(.hidden)
                }
                .onChange(of: linkedPost) {
                    if linkedPost != nil {
                        threadAutorefresher.cancelTimer()
                    } else {
                        updateAutoRefreshState()
                    }
                }
                .navigationDestination(item: $linkedPost) { destination in
                    PostDetailView(postID: destination.id)
                        .environment(viewModel)
                        .environment(presentationState)
                        .environment(\.galleryNamespace, galleryNamespace)
                }
                .sheet(isPresented: $appState.showingBottomSheet) {
                    if let post = appState.selectedBottomSheetPost,
                       let index = viewModel.posts.firstIndex(of: post) {
                        VStack(spacing: 24) {
                            Button("Reply on 4chan", systemImage: "arrowshape.turn.up.left") {
                                draftPost = DraftPost(id: post.no)
                                appState.showingBottomSheet = false
                                appState.selectedBottomSheetPost = nil
                            }
                            .accessibilityIdentifier("Draft Reply To Post")
                            Button("Copy Quote", systemImage: "quote.bubble") {
                                UIPasteboard.general.string = ">>\(post.no)"
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                appState.showingBottomSheet = false
                                appState.selectedBottomSheetPost = nil
                            }
                            .accessibilityIdentifier("Copy Selected Post Quote")
                            let isSaved = savedReplies.contains { $0.boardName == viewModel.boardName && $0.postID == post.no }
                            Button(isSaved ? "Remove Saved Reply" : "Save Reply", systemImage: isSaved ? "bookmark.slash" : "bookmark") {
                                saveReply(index: index)
                                appState.showingBottomSheet = false
                                appState.selectedBottomSheetPost = nil
                            }
                            .accessibilityIdentifier("Save Selected Reply")
                            ShareLink(item: viewModel.postURL(post.no)) {
                                Label("Share Post", systemImage: "square.and.arrow.up")
                            }
                            .accessibilityIdentifier("Share Selected Post")
                            Button("Hide \(index == 0 ? "Thread" : "Post")") {
                                recentlyHidden = HiddenPostStore.shared.hide(board: viewModel.boardName, postID: post.no,
                                                                             threadID: viewModel.id, title: index == 0 ? viewModel.title : nil)
                                appState.showingBottomSheet = false
                                appState.selectedBottomSheetPost = nil
                            }
                            .accessibilityIdentifier("Hide Selected Post")
                        }
                        .padding()
                        .presentationDetents([.height(350), .medium])
                        .presentationDragIndicator(.visible)
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if let item = recentlyHidden, HiddenPostStore.shared.isHidden(board: item.boardName, postID: item.postID) {
                        HStack {
                            Text(item.isThread ? "Thread hidden" : "Post hidden")
                            Spacer()
                            Button("Undo") {
                                HiddenPostStore.shared.restore(item)
                                recentlyHidden = nil
                            }
                            .accessibilityIdentifier("Undo Hide")
                            Button("Dismiss", systemImage: "xmark") { recentlyHidden = nil }
                                .labelStyle(.iconOnly)
                                .accessibilityLabel("Dismiss undo")
                        }
                        .font(.subheadline)
                        .padding()
                        .background(.regularMaterial)
                    }
                }
                .alert("Couldn’t Save Reply", isPresented: Binding(get: { bookmarkError != nil }, set: { if !$0 { bookmarkError = nil } })) {
                    Button("OK", role: .cancel) { bookmarkError = nil }
                } message: { Text(bookmarkError ?? "") }
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
        .background(theme.pageBackground)
        .safeAreaInset(edge: .top) {
            if viewModel.isArchived || viewModel.errorType == .notFound {
                let generals = followedGenerals.filter { $0.boardName == viewModel.boardName }
                if !generals.isEmpty {
                    Menu {
                        ForEach(generals) { general in
                            Button(general.effectiveDisplayName) { rolloverGeneral = general }
                        }
                    } label: {
                        Label("Find Next General", systemImage: "arrow.right.circle")
                            .frame(maxWidth: .infinity).padding(10).background(.regularMaterial)
                    }
                    .accessibilityIdentifier("Find Next General")
                }
            }
        }
        .sheet(item: $rolloverGeneral) { general in
            RecurringMatchSheet(favorite: general, excludingThreadID: viewModel.id) { post in
                nextGeneral = ThreadDestination(board: post.boardName, id: post.id)
            }
        }
        .navigationDestination(item: $nextGeneral) { destination in
            ThreadView(boardName: destination.board, postNumber: destination.id)
        }
        .sheet(item: $draftPost) { post in
            ReplyDraftSheet(board: viewModel.boardName, threadID: viewModel.id, postID: post.id)
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

                    if let posterID = viewModel.searchFilters.posterID {
                        FilterChip(
                            label: "ID: \(posterID)",
                            isSelected: true,
                            action: {
                                viewModel.searchFilters.posterID = nil
                            }
                        )
                    }
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

    @ViewBuilder
    var posterIDFilterBanner: some View {
        if let posterID = viewModel.searchFilters.posterID {
            HStack {
                let color = Color.randomColor(seed: posterID)
                Text("Showing posts by")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(posterID)
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(Color.isRandomColorLight(seed: posterID) ? .black : .white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(color)
                    .cornerRadius(5)
                Text("(\(viewModel.searchResultIndices.count))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    viewModel.searchFilters.posterID = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.regularMaterial)
        }
    }

    private var followedGeneral: RecurringFavorite? {
        guard let suggestion = GeneralSuggestion(title: viewModel.title) else { return nil }
        return followedGenerals.first {
            RecurringFavoriteDraft(boardName: $0.boardName, searchPattern: $0.searchPattern, displayName: "").map {
                $0.boardName == viewModel.boardName && $0.searchPattern == suggestion.tag
            } == true
        }
    }

    private var readablePostIDs: [Int] {
        viewModel.posts.enumerated().filter {
            !$0.element.isHidden(boardName: viewModel.boardName) && viewModel.filterEffect(at: $0.offset) != .hide
        }.map { $0.element.no }
    }

    private var unreadPostIDs: [Int] { reading.unreadPostIDs(in: readablePostIDs) }

    private func recordVisiblePosts() {
        guard rememberThreadPositions, isThreadVisible, scenePhase == .active, !isSearching,
              viewModel.searchText.isEmpty, viewModel.searchFilters == SearchFilters(), linkedPost == nil,
              !presentationState.presentingGallery, !presentationState.presentingReplies, !showFollowGeneral else { return }
        reading.observe(visiblePostIDs: visiblePostIDs)
        if let postID = reading.postID {
            ThreadReadingStore.shared.record(board: viewModel.boardName, threadID: viewModel.id,
                                             postID: postID, highestReadID: reading.highestReadID, title: viewModel.title)
        }
    }

    private var postLinkAction: OpenURLAction {
        OpenURLAction { url in
            if case .post(let id) = Deeplinker.getType(url: url) {
                if let index = viewModel.getPostIndexFromId(id) {
                    replyReturnPostID = reading.postID ?? visiblePostIDs.min()
                    linkedPost = PostDestination(id: viewModel.posts[index].no)
                } else {
                    showPostUnavailable = true
                }
                return .handled
            }
            return appState.openLink(url) ? .handled : .systemAction
        }
    }

    private func fetchAndPrefetchMedia() async {
        if await viewModel.getPosts() {
            viewModel.prefetch()
        }
    }

    private func updateAutoRefreshState() {
        if isThreadVisible, scenePhase == .active, !viewModel.isArchived,
           !presentationState.presentingGallery, !presentationState.presentingReplies,
           linkedPost == nil {
            threadAutorefresher.startTimer()
        } else {
            threadAutorefresher.cancelTimer()
        }
    }

    private func scrollToPost(reader: ScrollViewProxy) {
        if presentationState.presentingIndex != presentationState.galleryIndex,
           let mediaI = viewModel.postMediaMapping.firstIndex(where: { $0.value == presentationState.galleryIndex }) {
            reader.scrollTo(viewModel.posts[viewModel.postMediaMapping[mediaI].key].no, anchor: viewModel.media.count - presentationState.galleryIndex < 3 ? .bottom : .top)
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

    private func saveReply(index: Int) {
        let post = viewModel.posts[index]
        if let existing = savedReplies.first(where: { $0.boardName == viewModel.boardName && $0.postID == post.no }) {
            modelContext.delete(existing)
        } else {
            let text = post.com.map { String(CommentParser(comment: $0).getComment().characters) } ?? ""
            modelContext.insert(SavedReply(boardName: viewModel.boardName, threadID: viewModel.id,
                                          postID: post.no, threadTitle: viewModel.title, text: text))
        }
        do { try modelContext.save() } catch { bookmarkError = error.localizedDescription }
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

private struct DraftPost: Identifiable { let id: Int }

extension ThreadView {
    @ViewBuilder
    private var gallerySheetContent: some View {
        GalleryView(
            index: presentationState.galleryIndex
        )
        .environment(appState)
        .environment(presentationState)
        .environment(viewModel)
        .onAppear {
            threadAutorefresher.cancelTimer()
        }
        .onDisappear {
            updateAutoRefreshState()
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
