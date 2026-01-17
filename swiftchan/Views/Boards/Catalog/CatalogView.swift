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

    var boardName: String
    @State var catalogViewModel: CatalogViewModel
    @State var isShowingMenu: Bool = false
    @State var isSearching: Bool = false
    @State var showAddRecurringSheet: Bool = false

    let columns = [
        GridItem(.flexible(), spacing: 0, alignment: .top),
        GridItem(.flexible(), spacing: 0, alignment: .top)
    ]

    var scene: SKScene {
        let scene = SnowScene()
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        return scene
    }

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
        case .initial:
            CatalogLoadingView(viewModel: catalogViewModel)
                .task {
                    await catalogViewModel.load()
                }
        case .loading:
            CatalogLoadingView(viewModel: catalogViewModel)
        case .loaded:
            ScrollViewReader { reader in
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVGrid(
                        columns: columns,
                        alignment: .center,
                        spacing: 0
                    ) {
                        ForEach(Array(filteredPosts.enumerated()), id: \.element.id) { _, post in
                            if !post.post.isHidden(boardName: boardName) {
                                NavigationLink(value: post) {
                                    OPView(
                                        boardName: boardName,
                                        post: post
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .id(post.id)
                                .opacity(isSearching && !catalogViewModel.searchResultIndices.isEmpty ?
                                       (catalogViewModel.searchResultIndices[catalogViewModel.currentSearchResultIndex] == catalogViewModel.posts.firstIndex(where: { $0.id == post.id }) ? 1.0 : 0.5) : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: catalogViewModel.currentSearchResultIndex)
                            }
                        }
                    }
                }
                .onChange(of: catalogViewModel.currentSearchResultIndex) { _, _ in
                    if let postIndex = catalogViewModel.getCurrentSearchResultPostIndex(),
                       postIndex < catalogViewModel.posts.count {
                        let postId = catalogViewModel.posts[postIndex].id
                        withAnimation {
                            reader.scrollTo(postId, anchor: .center)
                        }
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if isSearching && !catalogViewModel.searchResultIndices.isEmpty {
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
            .onAppear {
                catalogViewModel.prefetch()
            }
            .onDisappear {
                catalogViewModel.stopPrefetching()
            }
            .navigationBarTitle(boardName)
            .navigationBarItems(
                trailing: settingsButton

            )
            .navigationDestination(for: SwiftchanPost.self) { post in
                ThreadView(
                    boardName: post.boardName,
                    postNumber: post.post.id
                )
            }
            .searchable(text: $catalogViewModel.searchText, isPresented: $isSearching)
            .onChange(of: catalogViewModel.searchText) { _, _ in
                catalogViewModel.updateSearchResults()
            }
            .onChange(of: catalogViewModel.searchFilters) { _, _ in
                catalogViewModel.updateSearchResults()
            }
            .refreshable {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                Task {
                    await catalogViewModel.load()
                    catalogViewModel.prefetch()
                }
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
                    Label("Save /\(catalogViewModel.searchText)/", systemImage: "repeat")
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
