//
//  BoardsView.swift
//  swiftchan
//
//  Created on 10/30/20.
//

import SwiftUI
import FourChan

struct BoardsView: View {
    @AppStorage("showNSFWBoards") private var showNSFWBoards: Bool = false
    @AppStorage("favoriteBoards") private var favoriteBoards: [String] = []
    @Environment(AppState.self) private var appState

    @State var boardsViewModel = BoardsViewModel()

    @State private var searchText: String = ""
    @State private var presentedNavigation = NavigationPath()

    @State private var showOpenLink = false

    var body: some View {
        NavigationStack(path: $presentedNavigation) {
            boardContent
                .navigationTitle(Constants.title)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Open Link", systemImage: "link") { showOpenLink = true }
                            .accessibilityIdentifier("Open Link Button")
                    }
                }
                .navigationDestination(for: String.self) { CatalogView(boardName: $0) }
                .navigationDestination(for: ThreadDestination.self) { destination in
                    ThreadView(boardName: destination.board, postNumber: destination.id, postID: destination.postID)
                }
                .sheet(isPresented: $showOpenLink) {
                    OpenLinkSheet { appState.openLink($0) }
                }
        }
        .onChange(of: appState.pendingLink, initial: true) {
            guard let link = appState.pendingLink else { return }
            switch link {
            case .board(let name):
                presentedNavigation.append(name)
            case .thread(let board, let id, let postID):
                if let number = Int(id) {
                    presentedNavigation.append(ThreadDestination(board: board, id: number, postID: postID))
                }
            case .post:
                break
            }
            appState.pendingLink = nil
        }
    }

    @ViewBuilder
    private var boardContent: some View {
        switch boardsViewModel.state {
        case .initial, .loading:
            BoardsLoadingView(viewModel: boardsViewModel)
                .task {
                    if boardsViewModel.state == .initial { await boardsViewModel.load() }
                }
        case .loaded:
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(alignment: .leading, spacing: Constants.gridSpacing) {
                    if searchText.isEmpty {
                        BoardSection(headerText: Constants.favoritesText, list: boardsViewModel.getFavoriteBoards(favoriteBoards))
                    }
                    BoardSection(headerText: Constants.allText, list: boardsViewModel.getFilteredBoards(searchText: searchText))
                }
            }
            .searchable(text: $searchText)
            .buttonStyle(.plain)
        case .error:
            ContentUnavailableView {
                Label("Couldn’t Load Boards", systemImage: "wifi.exclamationmark")
            } actions: {
                Button("Retry") { Task { await boardsViewModel.load() } }
            }
        }
    }

    struct Constants {
        static let favoritesText = "favorites"
        static let allText = "all"
        static let title = "4chan"
        static let refreshIcon = "arrow.clockwise"
        static let gridSpacing: CGFloat = 1
    }
}

struct BoardsLoadingView: View {
    let viewModel: BoardsViewModel

    var body: some View {
        VStack(spacing: 15) {
            Text("Loading Boards")
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
    BoardsView()
        .environment(AppState())
}
#endif
