//
//  BoardsView.swift
//  swiftchan
//
//  Created by vanities on 10/30/20.
//

import SwiftUI
import FourChan
import Defaults

struct BoardsView: View {
    @Default(.favoriteBoards) private var favoriteBoardsDefault
    @Default(.showNSFWBoards) private var showNSFWBoards
    @EnvironmentObject private var appState: AppState

    @StateObject var boardsViewModel = BoardsViewModel()

    @State var navigationSelection: String?
    @State private var searchText: String = ""
    @State private var showingSettings: Bool = false

    @ViewBuilder
    var body: some View {
        ZStack {
            switch boardsViewModel.state {
            case .loading, .initial, .error:
                ProgressView()
            case .loaded:
                NavigationView {
                    ZStack {
                        navigation
                            .hidden()
                        ScrollView(.vertical, showsIndicators: true) {
                            LazyVStack(alignment: .leading, spacing: Constants.gridSpacing) {
                                if searchText.isEmpty {
                                    BoardSection(
                                        headerText: Constants.favoritesText,
                                        list: boardsViewModel.getFavoriteBoards(),
                                        selection: $navigationSelection
                                    )
                                }
                                BoardSection(
                                    headerText: Constants.allText,
                                    list: boardsViewModel.getFilteredBoards(searchText: searchText),
                                    selection: $navigationSelection
                                )
                            }
                        }
                        .searchable(text: $searchText)
                    }
                    .navigationBarTitle(Constants.title)
                    .navigationBarItems(trailing: settingsButton)
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .onOpenURL { url in
                    if case .board(let name) = Deeplinker.getType(url: url) {
                        navigationSelection = name
                    }
                }
            }
        }
        .task {
            await boardsViewModel.load()
        }
    }

    var settingsButton: some View {
        NavigationLink(
            isActive: $showingSettings,
            destination: {
                SettingsView()
            },
            label: {
                Image(systemName: Constants.settingsIcon)
                    .foregroundColor(Color.primary)
            })
        .onTapGesture {
            showingSettings = true
        }
    }

    var navigation: some View {
        ForEach(boardsViewModel.getAllBoards(searchText: searchText)) { board in
            NavigationLink(
                tag: board.board,
                selection: $navigationSelection,
                destination: {CatalogView(boardName: board.board)},
                label: { EmptyView() }
            )
        }
    }

    struct Constants {
        static let favoritesText = "favorites"
        static let allText = "all"
        static let title = "4chan"
        static let settingsIcon = "gear"
        static let gridSpacing: CGFloat = 1
    }
}

#if DEBUG
struct BoardsView_Previews: PreviewProvider {
    static var previews: some View {
        BoardsView()
            .previewInterfaceOrientation(.portrait)
    }
}
#endif
