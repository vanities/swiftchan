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

    let columns = [GridItem(.flexible(), spacing: 0, alignment: .top), GridItem(.flexible(), spacing: 0, alignment: .top)]

    var navigationCentering: CGFloat {
        return CGFloat(20 + (self.viewModel.boardName.count * 5))
    }

    init(_ boardName: String) {
        self._viewModel = StateObject(wrappedValue: CatalogView.CatalogViewModel(boardName: boardName))
    }

    var filteredPostIndices: [Int] {
        guard searchText != "" else { return Array(viewModel.posts.indices) }
        return self.viewModel.posts.indices.compactMap { index -> Int? in
            let commentAndSubject = "\(viewModel.posts[index].com?.clean.lowercased() ?? "") \(viewModel.posts[index].sub?.clean.lowercased() ?? "")"

            return  commentAndSubject.contains(searchText.lowercased()) ? index : nil
        }
    }

    var body: some View {
        return ScrollViewReader { _ in
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
                                .accessibilityLabel("\(index) Thread")
                        }
                    }
                              .pullToRefresh(isRefreshing: $pullToRefreshShowing) {
                                  let softVibrate = UIImpactFeedbackGenerator(style: .soft)
                                  softVibrate.impactOccurred()
                                  viewModel.load {
                                      pullToRefreshShowing = false
                                  }
                              }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarTitle(viewModel.boardName)
        .navigationBarItems(
            trailing: FavoriteStar(viewModel: viewModel)
        )
        .searchable(text: $searchText)
    }
}

struct CatalogView_Previews: PreviewProvider {
    static var previews: some View {
        CatalogView("fit")
            .environmentObject(AppState())
            .environmentObject(UserSettings())
    }
}
