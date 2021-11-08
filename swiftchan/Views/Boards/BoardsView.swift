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
    @Default(.favoriteBoards) var favoriteBoardsDefault
    @ObservedObject var viewModel: ViewModel
    @State var searchText: String = ""
    @State var showingSettings: Bool = false

    let columns = [GridItem(.flexible(), spacing: 0, alignment: .topLeading)]

    var filteredBoards: [Board] {
        self.viewModel.boards.filter({ board in
            board.board.starts(with: self.searchText.lowercased())
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
                ActivityIndicator()
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVGrid(
                        columns: columns,
                        alignment: .leading,
                        spacing: 2
                    ) {
                        if searchText == "" {
                            Group {
                                Section(header: Text("favorites")
                                            .font(Font.system(size: 24, weight: .bold, design: .rounded))
                                            .padding(.leading, 5)
                                ) {

                                    ForEach(favoriteBoards) { board in
                                        NavigationLink(
                                            destination: {
                                                CatalogView(board.board)
                                            },
                                            label: {
                                                BoardView(name: board.board,
                                                          title: board.title,
                                                          description: board.meta_description.clean)
                                                    .padding(.horizontal, 5)
                                            })
                                            .id("\(board.id)-f")
                                            .accessibilityIdentifier(AccessibilityIdentifiers.boardButton( board.board))
                                    }
                                }

                            }
                        }
                        Section(header: Text("all")
                                    .font(Font.system(size: 24, weight: .bold, design: .rounded))
                                    .padding(.leading, 5)
                        ) {
                            ForEach(filteredBoards, id: \.self.id) { board in
                                NavigationLink(
                                    destination: {
                                        CatalogView(board.board)
                                    },
                                    label: {
                                    BoardView(name: board.board,
                                              title: board.title,
                                              description: board.meta_description.clean)
                                            .padding(.horizontal, 5)
                                    })
                                    .id("\(board.id)-a")
                                    .accessibilityIdentifier(AccessibilityIdentifiers.boardButton(board.board))
                            }
                        }
                    }
                    .searchable(text: $searchText)
                    .buttonStyle(PlainButtonStyle())
                    .navigationBarTitle("4chan")
                }
                .navigationBarItems(trailing: settingsButton)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
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
}

#if DEBUG
struct BoardsView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = BoardsView.ViewModel()
        BoardsView(viewModel: viewModel)
    }
}
#endif
