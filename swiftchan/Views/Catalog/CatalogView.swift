//
//  CatalogView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI
import FourChan

struct CatalogView: View {
    @ObservedObject var viewModel: ViewModel

    @State var searchText: String = ""
    @State var pullToRefreshShowing: Bool = false

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
            ScrollView {
                VStack(spacing: nil) {
                    SearchTextView(textPlaceholder: "Search Posts",
                                   searchText: self.$searchText)
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
                    .padding(.horizontal, 15)
                }
                .pullToRefresh(isRefreshing: self.$pullToRefreshShowing) {
                    let softVibrate = UIImpactFeedbackGenerator(style: .soft)
                    softVibrate.impactOccurred()
                    self.viewModel.load {
                        self.pullToRefreshShowing = false
                    }
                }
            }
            .navigationBarTitle(Text(self.viewModel.boardName), displayMode: .inline)
            .navigationBarItems(trailing: FavoriteStar(viewModel: self.viewModel))
    }
}

struct CatalogView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CatalogView.ViewModel(boardName: "fit")
        CatalogView(viewModel: viewModel)
    }
}
