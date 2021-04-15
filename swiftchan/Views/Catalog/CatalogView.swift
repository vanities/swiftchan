//
//  CatalogView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI
import FourChan

struct CatalogView: View {
    @StateObject var viewModel: ViewModel

    @State var searchText: String = ""
    @State var pullToRefreshShowing: Bool = false

    let columns = [GridItem(.flexible(), spacing: 0, alignment: .center), GridItem(.flexible(), spacing: 0, alignment: .center)]

    var navigationCentering: CGFloat {
        return CGFloat(20 + (self.viewModel.boardName.count * 5))
    }

    init(_ boardName: String) {
        self._viewModel = StateObject(wrappedValue: CatalogView.ViewModel(boardName: boardName))
    }

    var filteredPosts: [Post] {
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

    var body: some View {
        return
            ScrollViewReader { _ in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        if viewModel.posts.count == 0 {
                            ActivityIndicator()
                        } else {

                            SearchTextView(textPlaceholder: "Search Posts",
                                           searchText: self.$searchText)
                                .id("search")

                            LazyVGrid(columns: self.columns,
                                      alignment: .center,
                                      spacing: 0) {
                                ForEach(self.filteredPosts.indices, id: \.self) { index in
                                    OPView(boardName: self.viewModel.boardName,
                                           post: self.viewModel.posts[index],
                                           comment: self.viewModel.comments[index])
                                        .id(self.viewModel.posts[index].id)
                                    // .frame(width: UIScreen.main.bounds.width/2) //?
                                }
                            }
                            .padding(.horizontal, 15)
                            .pullToRefresh(isRefreshing: self.$pullToRefreshShowing) {
                                let softVibrate = UIImpactFeedbackGenerator(style: .soft)
                                softVibrate.impactOccurred()
                                self.viewModel.load {
                                    self.pullToRefreshShowing = false
                                }
                            }
                            .navigationBarTitleDisplayMode(.inline)
                            .navigationBarTitle(self.viewModel.boardName)
                            .navigationBarItems(
                                trailing: FavoriteStar(viewModel: self.viewModel)
                            )
                        }
                    }
                }
            }
    }
}

struct CatalogView_Previews: PreviewProvider {
    static var previews: some View {
        CatalogView("fit")
            .environmentObject(AppState())
            .environmentObject(UserSettings())
    }
}
