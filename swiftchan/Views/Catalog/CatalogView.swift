//
//  CatalogView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI
import FourChan
import Defaults
import MapKit
import BottomSheet

struct CatalogView: View {
    var boardName: String
    @EnvironmentObject var appState: AppState
    @StateObject var catalogViewModel: CatalogViewModel

    @State var searchText: String = ""
    @State var pullToRefreshShowing: Bool = false
    @State var isShowingMenu: Bool = false

    let columns = [
        GridItem(.flexible(), spacing: 0, alignment: .top),
        GridItem(.flexible(), spacing: 0, alignment: .top)
    ]

    init(boardName: String) {
        self.boardName = boardName
        self._catalogViewModel = StateObject(
            wrappedValue: CatalogViewModel(boardName: boardName)
        )
    }

    @ViewBuilder
    var body: some View {
        let filteredPosts = catalogViewModel.getFilteredPosts(searchText: searchText)
        switch catalogViewModel.state {
        case .loading:
            ProgressView()
                .task {
                    await catalogViewModel.load()
                }
        case .loaded:
            ScrollView(.vertical, showsIndicators: true) {
                LazyVGrid(
                    columns: columns,
                    alignment: .center,
                    spacing: 0
                ) {
                    ForEach(filteredPosts) { post in
                        if !post.post.isHidden(boardName: boardName) {
                            OPView(
                                boardName: boardName,
                                post: post
                            )
                        }
                    }
                }
                .pullToRefresh(isRefreshing: $pullToRefreshShowing) {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    Task {
                        await catalogViewModel.load()
                        DispatchQueue.main.async {
                            pullToRefreshShowing = false
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarTitle(boardName)
            .navigationBarItems(
                trailing: settingsButton

            )
            .searchable(text: $searchText)
            .bottomSheet(
                isPresented: $appState.showingCatalogMenu,
                height: 400
            ) {
                Group {
                    FavoriteStar(viewModel: catalogViewModel)
                    FilesSortRow(viewModel: catalogViewModel)
                    RepliesSortRow(viewModel: catalogViewModel)
                }
            }
        }
    }

    var settingsButton: some View {
        Button(action: {
            withAnimation {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                appState.showingCatalogMenu = true

            }
        }, label: {
            Image(systemName: "ellipsis")
        })
    }
}

#if DEBUG
struct CatalogView_Previews: PreviewProvider {
    static var previews: some View {
        CatalogView(boardName: "fit")
            .environmentObject(AppState())
    }
}
#endif
