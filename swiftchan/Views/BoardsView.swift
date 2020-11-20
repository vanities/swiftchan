//
//  BoardsView.swift
//  swiftchan
//
//  Created by vanities on 10/30/20.
//

import SwiftUI
import Introspect

struct BoardsView: View {
    @ObservedObject var viewModel: ViewModel
    @State var searchText: String = ""
    
    let columns = [GridItem(.flexible(), spacing: 0, alignment: .topLeading)]
    
    var body: some View {
        
        return NavigationView {
            VStack(spacing: 0) {
                SearchTextView(textPlaceholder: "Search Boards",
                               searchText: self.$searchText)
                ScrollView {
                    LazyVGrid(columns: columns,
                              alignment: .leading,
                              spacing: 2) {
                        ForEach(self.viewModel.boards, id: \.self.id) { board in
                            NavigationLink(
                                destination: CatalogView(viewModel: CatalogView.ViewModel(boardName: board.board))) {
                                if board.board.starts(with: self.searchText.lowercased()) {
                                    BoardView(name: board.board,
                                              title: board.title,
                                              description: board.meta_description.clean)
                                        .padding(.horizontal, 5)
                                }
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
