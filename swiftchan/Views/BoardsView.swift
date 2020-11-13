//
//  BoardsView.swift
//  swiftchan
//
//  Created by vanities on 10/30/20.
//

import SwiftUI
import Combine
import Alamofire

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
                        ForEach(self.viewModel.boards, id: \.self.name) { board in
                            NavigationLink(
                                destination: CatalogView(viewModel: CatalogView.ViewModel(boardName: board.name))
                            ) {
                                if board.name.starts(with: self.searchText.lowercased()) {
                                    BoardView(name: board.name,
                                              title: board.title,
                                              description: board.descriptionText)
                                        .padding(.horizontal, 5)
                                }
                            }
                        }
                    }
                    .navigationBarTitle("4chan")
                }
            }
        }
    }
}

struct BoardsView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = BoardsView.ViewModel()
        BoardsView(viewModel: viewModel)
    }
}
