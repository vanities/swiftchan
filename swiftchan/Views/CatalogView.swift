//
//  CatalogView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI
import FourChan

struct CatalogView: View {
    @EnvironmentObject var userSettings: UserSettings
    @ObservedObject var viewModel: ViewModel

    @State var searchText: String = ""

    let columns = [GridItem(.flexible(), spacing: 0, alignment: .center), GridItem(.flexible(), spacing: 0, alignment: .center)]

    var filteredPosts: [Post] {
        get {
            guard searchText != "" else { return self.viewModel.posts }
            return self.viewModel.posts.filter({ post in
                let splitComment = post.com?.split(separator: " ")
                let splitSubject = post.sub?.split(separator: " ")

                if let comment = splitComment {
                    for word in comment {
                        if word.lowercased().contains(self.searchText.lowercased()) {
                            return true
                        }
                    }
                }
                if let subject = splitSubject {
                    for word in subject {
                        if word.lowercased().contains(self.searchText.lowercased()) {
                            return true
                        }
                    }
                }
                return false
            })
        }
    }

    var body: some View {
        return
            VStack {
                SearchTextView(textPlaceholder: "Search Posts",
                               searchText: self.$searchText)
            ScrollView {
                LazyVGrid(columns: self.columns,
                          alignment: .center,
                          spacing: 0) {
                    ForEach(self.filteredPosts.indices,
                            id: \.self) { index in
                            OPView(boardName: self.viewModel.boardName,
                                   post: self.viewModel.posts[index],
                                   comment: self.viewModel.comments[index])
                    }
                }
            }
            }
            .navigationBarTitle(Text(self.viewModel.boardName), displayMode: .inline)
            // favorite
            .navigationBarItems(trailing:
                                    Image(systemName: self.userSettings.favoriteBoards.contains(self.viewModel.boardName) ? "star.fill" : "star").onTapGesture {
                                        let favorited = self.userSettings.favoriteBoards.contains(self.viewModel.boardName)

                                        if favorited {
                                            if let index = self.userSettings.favoriteBoards.firstIndex(of: self.viewModel.boardName) {
                                                self.userSettings.favoriteBoards.remove(at: index)
                                            }
                                        } else {
                                            self.userSettings.favoriteBoards.append(self.viewModel.boardName)
                                        }
                                    }
                                    .foregroundColor(.yellow)
            )
    }
}

struct CatalogView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CatalogView.ViewModel(boardName: "fit")
        CatalogView(viewModel: viewModel)
    }
}
