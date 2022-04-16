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
    @StateObject var viewModel: CatalogViewModel

    @State var searchText: String = ""
    @State var pullToRefreshShowing: Bool = false
    @State var isShowingMenu: Bool = false

    let columns = [
        GridItem(.flexible(), spacing: 0, alignment: .top),
        GridItem(.flexible(), spacing: 0, alignment: .top)
    ]

    var navigationCentering: CGFloat {
        return CGFloat(20 + (boardName.count * 5))
    }

    var sorting: Bool {
        !(Defaults.sortFilesBy(boardName: boardName) == .none &&
          Defaults.sortRepliesBy(boardName: boardName) == .none)
    }

    var filteredPosts: [SwiftchanPost] {
        if searchText.isEmpty {
            return viewModel.posts
        } else {
            return viewModel.posts.compactMap { swiftChanPost -> SwiftchanPost? in
                let commentAndSubject = "\(swiftChanPost.post.com?.clean.lowercased() ?? "") \(swiftChanPost.post.sub?.clean.lowercased() ?? "")"

                return commentAndSubject.contains(searchText.lowercased()) ? swiftChanPost : nil
            }
        }
    }

    init(boardName: String) {
        self.boardName = boardName
        self._viewModel = StateObject(wrappedValue: CatalogViewModel(boardName: boardName))
    }

    @ViewBuilder
    var body: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
                .onAppear {
                    viewModel.load()
                }
        case .loaded:
            ScrollView(.vertical, showsIndicators: true) {
                LazyVGrid(columns: columns,
                          alignment: .center,
                          spacing: 0) {
                    ForEach(filteredPosts, id: \.post.id) { post in
                        OPView(boardName: boardName,
                               post: post.post,
                               comment: post.comment)
                            .accessibilityIdentifier(AccessibilityIdentifiers.opButton(viewModel.posts.firstIndex(where: { $0.post == post.post}) ?? 0))
                    }
                }
                          .pullToRefresh(isRefreshing: $pullToRefreshShowing) {
                              UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                              viewModel.load {
                                  pullToRefreshShowing = false
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
                    FavoriteStar(viewModel: viewModel)
                    FilesSortRow(viewModel: viewModel)
                    RepliesSortRow(viewModel: viewModel)
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
