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
    @EnvironmentObject private var appState: AppState

    @StateObject var viewModel = ViewModel()

    @State var navigationSelection: String?
    @State private var searchText: String = ""
    @State private var showingSettings: Bool = false

    let columns = [GridItem(.flexible(), spacing: 0, alignment: .topLeading)]

    var filteredBoards: [Board] {
        viewModel.boards.filter({ board in
            board.board.starts(with: searchText.lowercased()) && !favoriteBoardsDefault.contains(board.board)
        })
    }

    var favoriteBoards: [Board] {
        viewModel.boards.filter({ board in
            favoriteBoardsDefault.contains(board.board)
        })
    }

    var body: some View {
        return NavigationView {
            if viewModel.boards.count == 0 {
                ProgressView()
            } else {
                ZStack {
                    navigation
                        .hidden()
                    ScrollView(.vertical, showsIndicators: true) {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            if searchText == "" {
                                BoardSection(
                                    headerText: "favorites",
                                    list: favoriteBoards,
                                    selection: $navigationSelection
                                )
                            }
                            BoardSection(
                                headerText: "all",
                                list: filteredBoards,
                                selection: $navigationSelection
                            )
                        }
                    }
                    .searchable(text: $searchText)
                }
                .navigationBarTitle("4chan")
                .navigationBarItems(trailing: settingsButton)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onOpenURL { url in
            if case .board(let name) = Deeplinker.getType(url: url) {
                navigationSelection = name
            }
        }
    }

    var settingsButton: some View {
        NavigationLink(
            isActive: $showingSettings,
            destination: {
                SettingsView()
            },
            label: {
                Image(systemName: "gear")
                    .foregroundColor(Color.primary)
            })
            .onTapGesture {
                showingSettings = true
            }
    }

    var navigation: some View {
        ForEach(favoriteBoards + filteredBoards, id: \.self) { board in
            NavigationLink(
                tag: board.board,
                selection: $navigationSelection,
                destination: {CatalogView(boardName: board.board)},
                label: { EmptyView() }
            )
        }
    }
}

#if DEBUG
struct BoardsView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = BoardsView.ViewModel()
        BoardsView(viewModel: viewModel)
    }
}
#endif
