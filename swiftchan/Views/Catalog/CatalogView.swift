//
//  CatalogView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI
import FourChan
import SwiftlySearch

struct CatalogView: View {
    @StateObject var viewModel: CatalogViewModel

    @State var searchText: String = ""
    @State var pullToRefreshShowing: Bool = false

    let columns = [GridItem(.flexible(), spacing: 0, alignment: .center), GridItem(.flexible(), spacing: 0, alignment: .center)]

    var navigationCentering: CGFloat {
        return CGFloat(20 + (self.viewModel.boardName.count * 5))
    }

    init(_ boardName: String) {
        self._viewModel = StateObject(wrappedValue: CatalogView.CatalogViewModel(boardName: boardName))
    }

    var filteredPostIndices: [Int] {
        guard searchText != "" else { return Array(viewModel.posts.indices) }
        return self.viewModel.posts.indices.compactMap { index -> Int? in
            let comment = viewModel.comments[index].string.replacingOccurrences(of: "\n", with: " ")
            let subject = viewModel.posts[index].sub?.clean ?? ""
            let commentAndSubject = comment.lowercased() + " " + subject.lowercased()
            let match = (commentAndSubject).contains(searchText.lowercased())
            return match ? index : nil
        }
    }

    var body: some View {
        return
            ScrollViewReader { _ in
                ScrollView(.vertical, showsIndicators: true) {
                    if viewModel.posts.count == 0 {
                        ActivityIndicator()
                    } else {
                        LazyVGrid(columns: columns,
                                  alignment: .center,
                                  spacing: 0) {
                            ForEach(filteredPostIndices, id: \.self) { index in
                                OPView(boardName: viewModel.boardName,
                                       post: viewModel.posts[index],
                                       comment: viewModel.comments[index])
                            }
                        }
                        .padding(.horizontal, 15)
                        .pullToRefresh(isRefreshing: $pullToRefreshShowing) {
                            let softVibrate = UIImpactFeedbackGenerator(style: .soft)
                            softVibrate.impactOccurred()
                            viewModel.load {
                                pullToRefreshShowing = false
                            }
                        }
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationBarTitle(viewModel.boardName)
                        .navigationBarItems(
                            trailing: FavoriteStar(viewModel: viewModel)
                        )
                    }
                }
            }
            .navigationBarSearch($searchText, placeholder: "Search Posts", hidesNavigationBarDuringPresentation: true, hidesSearchBarWhenScrolling: true, cancelClicked: {}, searchClicked: {})
    }
}

struct CatalogView_Previews: PreviewProvider {
    static var previews: some View {
        CatalogView("fit")
            .environmentObject(AppState())
            .environmentObject(UserSettings())
    }
}
