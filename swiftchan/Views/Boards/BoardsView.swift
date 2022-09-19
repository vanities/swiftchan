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

    @State private var searchText: String = ""
    @State private var presentedNavigation = NavigationPath()
    let settingNavigation = "settings"

    @ViewBuilder
    var body: some View {
        ZStack {
            switch boardsViewModel.state {
            case .loading, .initial:
                ProgressView()
            case .loaded:
                NavigationStack(path: $presentedNavigation) {
                    ZStack {
                        ScrollView(.vertical, showsIndicators: true) {
                            LazyVStack(alignment: .leading, spacing: Constants.gridSpacing) {
                                if searchText.isEmpty {
                                    BoardSection(
                                        headerText: Constants.favoritesText,
                                        list: boardsViewModel.getFavoriteBoards()
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
                    .navigationBarItems(trailing: settingsButton)
                    .navigationDestination(for: String.self) { value in
                        if value == settingNavigation {
                            SettingsView()
                        } else {
                            CatalogView(boardName: value)
                        }
                    }
                }
                .onOpenURL { url in
                    if case .board(let name) = Deeplinker.getType(url: url) {
                        presentedNavigation.append(name)
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
        .task {
            await boardsViewModel.load()
        }
    }

    var settingsButton: some View {
        NavigationLink(value: settingNavigation) {
            Image(systemName: Constants.settingsIcon)
                .foregroundColor(Color.primary)
        }
    }

    struct Constants {
        static let favoritesText = "favorites"
        static let allText = "all"
        static let title = "4chan"
        static let settingsIcon = "gear"
        static let refreshIcon = "arrow.clockwise"
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
