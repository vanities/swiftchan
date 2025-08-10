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
import ToastUI

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
                            threadAutorefresher.startTimer()
                        }
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
                Text("Thread contains no posts.")
                    .foregroundColor(.red)
            }
        }
        .toast(isPresented: $showAutoRefreshToast, dismissAfter: 0.5) {
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

struct ThreadLoadingView: View {
    let viewModel: ThreadViewModel
    @State private var downloadPercentage: Int = 0

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

            Text("\(downloadPercentage)%")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.accentColor)

            ProgressView(value: Double(downloadPercentage), total: 100.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .frame(maxWidth: 250)
        }
        .padding()
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            downloadPercentage = Int(viewModel.downloadProgress.fractionCompleted * 100)
        }
    }
}

struct RefreshProgressBar: View {
    let progress: Double
    let total: Double
    let isPaused: Bool

    private var percentage: Double {
        guard total > 0 else { return 0 }
        return max(0, min(1, (total - progress) / total))
    }

    private var barColor: Color {
        if isPaused {
            return Color.gray
        }

        switch percentage {
        case 0.5...1.0:
            return Color.green
        case 0.25..<0.5:
            return Color.orange
        default:
            return Color.red
        }
    }

    var body: some View {
        GeometryReader { outerGeometry in
            ZStack(alignment: .leading) {
                // Background shape - always full width
                CornerWrapShape(isIPhone: UIDevice.current.userInterfaceIdiom == .phone)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: outerGeometry.size.width, height: 30)
                
                // Progress bar - mask the background shape instead of creating a new shape
                CornerWrapShape(isIPhone: UIDevice.current.userInterfaceIdiom == .phone)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: outerGeometry.size.width, height: 30)
                    .mask(
                        Rectangle()
                            .frame(width: outerGeometry.size.width * percentage, height: 30)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    )
                    .overlay(
                        CornerWrapShape(isIPhone: UIDevice.current.userInterfaceIdiom == .phone)
                            .fill(barColor)
                            .frame(width: outerGeometry.size.width, height: 30)
                            .mask(
                                Rectangle()
                                    .frame(width: outerGeometry.size.width * percentage, height: 30)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            )
                    )
                    .animation(.linear(duration: 0.5), value: percentage)
            }
        }
        .frame(height: 30)
        .opacity(isPaused ? 0.5 : 1.0)
    }
}

struct CornerWrapShape: Shape {
    let isIPhone: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        if isIPhone {
            let cornerRadius: CGFloat = 75
            let barHeight: CGFloat = 6
            
            // Start from bottom left, wrap up the corner
            path.move(to: CGPoint(x: 0, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height - cornerRadius))
            path.addQuadCurve(
                to: CGPoint(x: cornerRadius, y: rect.height - barHeight),
                control: CGPoint(x: 0, y: rect.height - barHeight)
            )
            
            // Straight line across the bottom
            path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: rect.height - barHeight))
            
            // Wrap up the right corner
            path.addQuadCurve(
                to: CGPoint(x: rect.width, y: rect.height - cornerRadius),
                control: CGPoint(x: rect.width, y: rect.height - barHeight)
            )
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            
            // Close the path along the bottom
            path.addLine(to: CGPoint(x: 0, y: rect.height))
        } else {
            // Simple rectangle for non-iPhone devices
            let barHeight: CGFloat = 6
            path.addRect(CGRect(x: 0, y: rect.height - barHeight, width: rect.width, height: barHeight))
        }
        
        return path
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
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
