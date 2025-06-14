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

    @ViewBuilder
    var body: some View {
        switch boardsViewModel.state {
        case .initial:
            Text(boardsViewModel.progressText)
                .task {
                    await boardsViewModel.load()
                }
        case .loading:
            Text(boardsViewModel.progressText)
        case .loaded:
            NavigationStack(path: $presentedNavigation) {
                ZStack {
                    ScrollView(.vertical, showsIndicators: true) {
                        LazyVStack(alignment: .leading, spacing: Constants.gridSpacing) {
                            if searchText.isEmpty {
                                BoardSection(
                                    headerText: Constants.favoritesText,
                                    list: boardsViewModel.getFavoriteBoards(favoriteBoards)
                                )
                            }
                            BoardSection(
                                headerText: Constants.allText,
                                list: boardsViewModel.getFilteredBoards(searchText: searchText)
                            )
                        }
                    }
                    .searchable(text: $searchText)
                }
                .buttonStyle(.plain)
                .navigationBarTitle(Constants.title)
                .navigationDestination(for: String.self) { value in
                    CatalogView(boardName: value)
                }
                .navigationDestination(for: ThreadDestination.self) { dest in
                    ThreadView(boardName: dest.board, postNumber: dest.id)
                }
            }
            .onOpenURL { url in
                switch Deeplinker.getType(url: url) {
                case .board(let name):
                    presentedNavigation.append(name)
                case .thread(let board, let id):
                    presentedNavigation.append(ThreadDestination(board: board, id: Int(id) ?? 0))
                default:
                    break
                }
            }
        case .error:
            VStack {
                Image(systemName: Constants.refreshIcon)
                    .frame(width: 25, height: 25)
                Text("Error loading boards, Tap to retry.")
            }.onTapGesture {
                Task {
                    await boardsViewModel.load()
                }
            }
            .foregroundColor(Color.red)
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

#if DEBUG
#Preview {
    BoardsView()
        .environment(AppState())
}
#endif
