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
    @State var boards: [Board] = []
    @State var loaded: Bool = false
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
                        ForEach(self.boards, id: \.self.board) { board in
                            NavigationLink(
                                destination: CatalogView(boardName: board.board)
                            ) {
                                if board.board.starts(with: self.searchText.lowercased()) {
                                    BoardView(name: board.board,
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
        .onAppear {
            if !self.loaded {
                self.getBoards()
                self.loaded.toggle()
            }
        }

    }

    private func getBoards() {
        let url = "https://a.4cdn.org/boards.json"

        let headers: HTTPHeaders = [
            .accept("application/json")
        ]

        /*
         see json
         AF.request(url, headers: headers)
         .validate()
         .responseJSON { (data) in
         print(data)
         }
         */

        AF.request(url, headers: headers)
            .validate()
            .responseDecodable(of: Boards.self) { (response) in
                guard let boards = response.value else { return }
                self.boards = boards.all
            }
    }
}

struct BoardsView_Previews: PreviewProvider {
    static var previews: some View {
        let boards = [
            Board(board: "3", title: "3DCG", description: "/3/ - 3DCG is 4chan's board for 3D modeling and imagery."),
            Board(board: "a", title: "Anime & Manga", description: "/a/ - Anime  Manga is 4chan's imageboard dedicated to the discussion of Japanese animation and manga.")
        ]
        BoardsView(boards: boards)
    }
}
