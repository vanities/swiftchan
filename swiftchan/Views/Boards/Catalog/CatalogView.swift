//
//  CatalogView.swift
//  swiftchan
//
//  Created on 10/31/20.
//

import SwiftUI
import FourChan
import SpriteKit

struct CatalogView: View {
    @AppStorage("hideTabOnBoards") var hideTabOnBoards = false

    @Environment(AppState.self) var appState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var boardName: String
    @State var catalogViewModel: CatalogViewModel
    @State var isShowingMenu: Bool = false
    @State var isSearching: Bool = false
    @State var showAddRecurringSheet: Bool = false

    @State private var selectedThread: SwiftchanPost?
    @State private var usesThreadWorkspace = false
    @State private var usesDuoArrangement = false

    @State private var scene: SKScene = {
        let s = SnowScene()
        s.scaleMode = .resizeFill
        s.backgroundColor = .clear
        return s
    }()

    init(boardName: String) {
        self.boardName = boardName
        self._catalogViewModel = State(
            wrappedValue: CatalogViewModel(boardName: boardName)
        )
    }

    @ViewBuilder
    var body: some View {
        @Bindable var appState = appState
        let filteredPosts = catalogViewModel.getFilteredPostsWithFilters(searchText: catalogViewModel.searchText, filters: catalogViewModel.searchFilters)

        switch catalogViewModel.state {
        case .initial, .loading:
            CatalogLoadingView(viewModel: catalogViewModel)
                .task {
                    if catalogViewModel.state == .initial {
                        await catalogViewModel.load()
                    }
                }
        case .loaded:
            GeometryReader { geometry in
                let layout = workspaceLayout(in: geometry)
                let twoColumnGrid = hasActiveDuoDivision(in: geometry)
                    || (horizontalSizeClass == .compact && !hasDuoDivision(in: geometry))
                Group {
                    if usesThreadWorkspace {
#if IPHONE_DUO_LAYOUTS
                        if #available(iOS 27.1, *), usesDuoArrangement {
                            let insets = duoDivisionInsets(in: geometry)
                            ArrangementView {
                                catalogPosts(filteredPosts, workspace: true, twoColumns: twoColumnGrid)
                                    .padding(insets.primary)
                            } secondary: {
                                workspaceThread
                                    .padding(insets.secondary)
                            }
                            .arrangementViewStyle(.split)
                            .accessibilityIdentifier("BoardThreadWorkspace")
                            .navigationBarBackButtonHidden(true)
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Back to boards", systemImage: "chevron.left") { dismiss() }
                                }
                            }
                        } else {
                            sideBySideWorkspace(filteredPosts, layout: layout)
                        }
#else
                        sideBySideWorkspace(filteredPosts, layout: layout)
#endif
                    } else {
                        catalogPosts(filteredPosts, workspace: false, twoColumns: twoColumnGrid)
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { usesThreadWorkspace = wantsWorkspace(in: geometry) }
                }
                .onGeometryChange(for: Bool.self) { hasDuoDivision(in: $0) } action: { hasDivision in
                    // Background snapshots may omit reserved regions. Once the
                    // device exposes a division, retain its container identity.
                    if hasDivision { usesDuoArrangement = true }
                }
            }
            .onGeometryChange(for: Bool.self) { wantsWorkspace(in: $0) } action: { isWide in
                // Background snapshots can briefly use compact dimensions. Keep
                // them from pushing the selected thread onto the navigation stack.
                if scenePhase == .active { usesThreadWorkspace = isWide }
            }
            .navigationDestination(item: Binding(
                get: { usesThreadWorkspace ? nil : selectedThread },
                set: { if !usesThreadWorkspace { selectedThread = $0 } }
            )) { post in
                ThreadView(boardName: post.boardName, postNumber: post.id)
            }
            .overlay(alignment: .bottom) {
                if isSearching && !catalogViewModel.searchResultIndices.isEmpty {
                    searchToolbar
                }
            }
            .safeAreaInset(edge: .top) {
                if let error = catalogViewModel.refreshError {
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
            .onAppear {
                catalogViewModel.prefetch()
            }
            .onDisappear {
                catalogViewModel.stopPrefetching()
            }
            .navigationBarTitle(boardName)
            .navigationBarTitleDisplayMode(usesThreadWorkspace ? .inline : .automatic)
            .navigationBarItems(
                trailing: settingsButton

            )
            .searchable(text: $catalogViewModel.searchText, isPresented: $isSearching)
            .onChange(of: catalogViewModel.searchText) { _, _ in
                catalogViewModel.updateSearchResults()
            }
            .onChange(of: catalogViewModel.searchFilters) { _, _ in
                catalogViewModel.updateSearchResults()
            }
            .refreshable {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                await catalogViewModel.load()
                catalogViewModel.prefetch()
            }
            .sheet(isPresented: $appState.showingCatalogMenu) {
                Group {
                    FavoriteStar(viewModel: catalogViewModel)
                    FilesSortRow(viewModel: catalogViewModel)
                    RepliesSortRow(viewModel: catalogViewModel)
                }
                .presentationDetents([.fraction(0.4)])
            }
            .sheet(isPresented: $showAddRecurringSheet) {
                AddRecurringFavoriteSheet(
                    searchPattern: catalogViewModel.searchText,
                    boardName: boardName,
                    onSave: {
                        // Clear search and switch to favorites
                        catalogViewModel.searchText = ""
                        isSearching = false
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        appState.selectedTab = .favorites
                    }
                )
            }
            .toolbar(hideTabOnBoards ? .hidden : .automatic, for: .tabBar)
        case .error:
            VStack {
                Image(systemName: Constants.refreshIcon)
                    .frame(width: 25, height: 25)
                Text("Error loading catalog, Tap to retry.")
            }.onTapGesture {
                Task {
                    await catalogViewModel.load()
                    catalogViewModel.prefetch()
                }
            }
            .foregroundColor(Color.red)
        }
    }

    private func wantsWorkspace(in geometry: GeometryProxy) -> Bool {
        geometry.size.width >= 760 || (horizontalSizeClass == .regular && geometry.size.width >= 580)
    }

    private func duoDivisionInsets(in geometry: GeometryProxy) -> (primary: EdgeInsets, secondary: EdgeInsets) {
#if IPHONE_DUO_LAYOUTS
        if #available(iOS 27.1, *) {
            // Keep the same container when the hinge becomes inactive. Replacing
            // it with NavigationSplitView can hide the catalog and recreate the thread.
            var primary = EdgeInsets()
            var secondary = EdgeInsets()
            if let fold = geometry.reservedRegions(kind: .division).first {
                if fold.frame.width > fold.frame.height {
                    primary.bottom = fold.margins.bottom
                    secondary.top = fold.margins.top
                } else {
                    primary.trailing = fold.margins.trailing
                    secondary.leading = fold.margins.leading
                }
            }
            return (primary, secondary)
        }
#endif
        return (EdgeInsets(), EdgeInsets())
    }

    private func hasDuoDivision(in geometry: GeometryProxy) -> Bool {
#if IPHONE_DUO_LAYOUTS
        if #available(iOS 27.1, *) {
            return !geometry.reservedRegions(kind: .division, options: .includeInactive).isEmpty
        }
#endif
        return false
    }

    private func hasActiveDuoDivision(in geometry: GeometryProxy) -> Bool {
#if IPHONE_DUO_LAYOUTS
        if #available(iOS 27.1, *) {
            return !geometry.reservedRegions(kind: .division).isEmpty
        }
#endif
        return false
    }

    @ViewBuilder
    private var workspaceThread: some View {
        if let selectedThread {
            ThreadView(boardName: selectedThread.boardName, postNumber: selectedThread.id,
                       showsNavigationTitle: false)
                .id(selectedThread.id)
                .accessibilityIdentifier("CatalogThreadDetail")
        } else {
            ContentUnavailableView {
                Label("Open a Thread", systemImage: "text.bubble")
            } description: {
                Text("Choose a discussion from the board. Browse the board while you read.")
            }
        }
    }

    private func sideBySideWorkspace(_ posts: [SwiftchanPost], layout: (sidebarWidth: CGFloat?, hingeGap: CGFloat)) -> some View {
        NavigationSplitView {
            catalogPosts(posts, workspace: true, twoColumns: horizontalSizeClass == .compact)
                .navigationSplitViewColumnWidth(
                    min: layout.sidebarWidth ?? 260,
                    ideal: layout.sidebarWidth ?? 320,
                    max: layout.sidebarWidth ?? 400
                )
        } detail: {
            NavigationStack {
                workspaceThread
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Back to boards", systemImage: "chevron.left") { dismiss() }
                        }
                    }
            }
            .padding(.leading, layout.hingeGap)
        }
        .navigationSplitViewStyle(.balanced)
        .accessibilityIdentifier("BoardThreadWorkspace")
    }

    private func workspaceLayout(in geometry: GeometryProxy) -> (sidebarWidth: CGFloat?, hingeGap: CGFloat) {
        #if IPHONE_DUO_LAYOUTS
            if #available(iOS 27.1, *),
               let fold = geometry.reservedRegions(kind: .division).first(where: {
                   $0.frame.height > $0.frame.width && $0.frame.minX > 0 && $0.frame.maxX < geometry.size.width
               }) {
                // Preserve the same navigation containers across pose changes,
                // while moving both columns' content clear of the physical hinge.
                let leadingWidth = fold.frame.minX - fold.margins.leading
                let gap = fold.frame.width + fold.margins.leading + fold.margins.trailing
                return (leadingWidth, gap)
            }
        #endif
        return (nil, 0)
    }

    private func catalogPosts(_ posts: [SwiftchanPost], workspace: Bool, twoColumns: Bool) -> some View {
        GeometryReader { geometry in
            let inset: CGFloat = workspace ? 10 : 0
            let count = twoColumns ? 2 : max(2, Int((geometry.size.width - inset * 2) / 140))
            let columns = Array(repeating: GridItem(.flexible(), spacing: 0, alignment: .top), count: count)
            ScrollViewReader { reader in
                ScrollView(.vertical) {
                    LazyVGrid(columns: columns, alignment: .center, spacing: 0) {
                        ForEach(posts) { post in
                            if !post.post.isHidden(boardName: boardName),
                               PostFilterStore.shared.effect(board: boardName, post: post.post, text: String(post.comment.characters)) != .hide {
                                Button {
                                    selectedThread = post
                                } label: {
                                    OPView(boardName: boardName, post: post)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: OPView.Constants.backgroundCornerRadius)
                                                .strokeBorder(selectedThread?.id == post.id ? Color.accentColor : .clear, lineWidth: 2)
                                        }
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("CatalogThread\(post.id)")
                                .id(post.id)
                                .opacity(isSearching && !catalogViewModel.searchResultIndices.isEmpty ?
                                    (catalogViewModel.getCurrentSearchResultPostIndex().map { catalogViewModel.posts[$0].id } == post.id ? 1 : 0.5) : 1)
                            }
                        }
                    }
                    .padding(inset)
                }
                .accessibilityIdentifier("Catalog Threads")
                .onChange(of: catalogViewModel.currentSearchResultIndex) { _, _ in
                    if let index = catalogViewModel.getCurrentSearchResultPostIndex(), catalogViewModel.posts.indices.contains(index) {
                        withAnimation { reader.scrollTo(catalogViewModel.posts[index].id, anchor: .center) }
                    }
                }
            }
        }
    }

    var settingsButton: some View {
        Button(action: {
            withAnimation {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                appState.showingCatalogMenu = true

            }
        }, label: {
            Image(systemName: "ellipsis")
        })
    }

    struct Constants {
        static let refreshIcon = "arrow.clockwise"
    }

    @ViewBuilder
    var searchToolbar: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CatalogFilterChip(
                        label: "Has Media",
                        isSelected: catalogViewModel.searchFilters.hasMedia,
                        action: {
                            catalogViewModel.searchFilters.hasMedia.toggle()
                        }
                    )

                    CatalogFilterChip(
                        label: "10+ Replies",
                        isSelected: catalogViewModel.searchFilters.minReplies == 10,
                        action: {
                            if catalogViewModel.searchFilters.minReplies == 10 {
                                catalogViewModel.searchFilters.minReplies = nil
                            } else {
                                catalogViewModel.searchFilters.minReplies = 10
                            }
                        }
                    )

                    CatalogFilterChip(
                        label: "20+ Replies",
                        isSelected: catalogViewModel.searchFilters.minReplies == 20,
                        action: {
                            if catalogViewModel.searchFilters.minReplies == 20 {
                                catalogViewModel.searchFilters.minReplies = nil
                            } else {
                                catalogViewModel.searchFilters.minReplies = 20
                            }
                        }
                    )

                    CatalogFilterChip(
                        label: "5+ Images",
                        isSelected: catalogViewModel.searchFilters.minImages == 5,
                        action: {
                            if catalogViewModel.searchFilters.minImages == 5 {
                                catalogViewModel.searchFilters.minImages = nil
                            } else {
                                catalogViewModel.searchFilters.minImages = 5
                            }
                        }
                    )
                }
                .padding(.horizontal)
            }

            HStack {
                Text("\(catalogViewModel.currentSearchResultIndex + 1) of \(catalogViewModel.searchResultIndices.count) threads")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    showAddRecurringSheet = true
                }) {
                    Label("Follow a General", systemImage: "repeat")
                        .font(.caption)
                }
                .disabled(catalogViewModel.searchText.isEmpty)

                Button(action: {
                    catalogViewModel.jumpToPreviousSearchResult()
                }) {
                    Image(systemName: "chevron.up")
                        .padding(8)
                }
                .disabled(catalogViewModel.searchResultIndices.isEmpty)

                Button(action: {
                    catalogViewModel.jumpToNextSearchResult()
                }) {
                    Image(systemName: "chevron.down")
                        .padding(8)
                }
                .disabled(catalogViewModel.searchResultIndices.isEmpty)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(.regularMaterial)
    }
}

struct CatalogFilterChip: View {
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

struct CatalogLoadingView: View {
    let viewModel: CatalogViewModel

    var body: some View {
        VStack(spacing: 15) {
            Text("Loading /\(viewModel.boardName)/")
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
    CatalogView(boardName: "fit")
        .environment(AppState())
}
#endif
