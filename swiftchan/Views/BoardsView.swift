//
//  BoardsView.swift
//  swiftchan
//
//  Created by vanities on 10/30/20.
//

import SwiftUI
import FourChan

struct BoardsView: View {
    @ObservedObject var viewModel: ViewModel
    @State var searchText: String = ""

    let columns = [GridItem(.flexible(), spacing: 0, alignment: .topLeading)]

    var filteredBoards: [Board] {
        get {
            return self.viewModel.boards.filter({ board in
                board.board.starts(with: self.searchText.lowercased())

            })
        }
    }

    var body: some View {
        return NavigationView {
            VStack(spacing: 0) {
                SearchTextView(textPlaceholder: "Search Boards",
                               searchText: self.$searchText)
                ScrollView {
                    LazyVGrid(columns: columns,
                              alignment: .leading,
                              spacing: 2) {
                        ForEach(self.filteredBoards, id: \.self.id) { board in
                            NavigationLink(
                                destination: CatalogView(viewModel: CatalogView.ViewModel(boardName: board.board))) {
                                    BoardView(name: board.board,
                                              title: board.title,
                                              description: board.meta_description.clean)
                                        .padding(.horizontal, 5)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .navigationBarTitle("4chan")
                }
            }
        }
    }
}
