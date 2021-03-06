//
//  BoardsView.swift
//  swiftchan
//
//  Created by vanities on 10/30/20.
//

import SwiftUI
import FourChan

struct BoardsView: View {
    @EnvironmentObject var userSettings: UserSettings
    @ObservedObject var viewModel: ViewModel
    @State var searchText: String = ""

    let columns = [GridItem(.flexible(), spacing: 0, alignment: .topLeading)]

    var filteredBoards: [Board] {
        self.viewModel.boards.filter({ board in
            board.board.starts(with: self.searchText.lowercased())
        })
    }

    var favoriteBoards: [Board] {
        self.viewModel.boards.filter({ board in
            self.userSettings.favoriteBoards.contains(board.board)
        })
    }

    var body: some View {
        return NavigationView {
            if viewModel.boards.count == 0 {
                ActivityIndicator()
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVGrid(
                        columns: self.columns,
                        alignment: .leading,
                        spacing: 2
                    ) {
                        if self.searchText == "" {
                            Group {
                                Section(header: Text("favorites")
                                            .font(Font.system(size: 24, weight: .bold, design: .rounded))
                                            .padding(.leading, 5)
                                ) {

                                    ForEach(self.favoriteBoards) { board in
                                        NavigationLink(
                                            destination:
                                                CatalogView(board.board)
                                        ) {
                                            BoardView(name: board.board,
                                                      title: board.title,
                                                      description: board.meta_description.clean)
                                                .padding(.horizontal, 5)
                                        }
                                        .id("\(board.id)-f")
                                    }
                                }

                            }
                        }
                        Section(header: Text("all")
                                    .font(Font.system(size: 24, weight: .bold, design: .rounded))
                                    .padding(.leading, 5)
                        ) {
                            ForEach(self.filteredBoards, id: \.self.id) { board in
                                NavigationLink(
                                    destination: CatalogView(board.board)) {
                                    BoardView(name: board.board,
                                              title: board.title,
                                              description: board.meta_description.clean)
                                        .padding(.horizontal, 5)
                                }
                                .id("\(board.id)-a")
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .navigationBarTitle("4chan")
                    .navigationBarSearch(
                        $searchText,
                        placeholder: "Search Boards",
                        hidesNavigationBarDuringPresentation: true,
                        hidesSearchBarWhenScrolling: true,
                        cancelClicked: {},
                        searchClicked: {}
                    )
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct BoardsView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = BoardsView.ViewModel()
        BoardsView(viewModel: viewModel)
    }
}
