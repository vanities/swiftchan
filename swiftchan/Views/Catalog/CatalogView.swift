//
//  CatalogView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI
import FourChan
import Defaults

struct CatalogView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel: CatalogViewModel

    @State var searchText: String = ""
    @State var pullToRefreshShowing: Bool = false
    @State var isShowingMenu: Bool = false

    let columns = [
        GridItem(.flexible(), spacing: 0, alignment: .top),
        GridItem(.flexible(), spacing: 0, alignment: .top)
    ]

    var navigationCentering: CGFloat {
        return CGFloat(20 + (self.viewModel.boardName.count * 5))
    }

    var sorting: Bool {
        !(Defaults.sortFilesBy(boardName: viewModel.boardName) == .none &&
          Defaults.sortRepliesBy(boardName: viewModel.boardName) == .none)
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

    @ViewBuilder
    var body: some View {
        ZStack {
            switch viewModel.state {
            case .loading:
                ProgressView()
            case .loaded:
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVGrid(columns: columns,
                              alignment: .center,
                              spacing: 0) {
                        ForEach(filteredPosts, id: \.post.id) { post in
                            OPView(boardName: viewModel.boardName,
                                   post: post.post,
                                   comment: post.comment)
                                .accessibilityIdentifier(AccessibilityIdentifiers.opButton(viewModel.posts.firstIndex(where: { $0.post == post.post}) ?? 0))
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
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarTitle(viewModel.boardName)
                .navigationBarItems(
                    trailing:
                        HStack {
                            sortingButton
                            settingsButton
                        }
                )
                .searchable(text: $searchText)
                .multiActionSheet(isPresented: $appState.showingCatalogMenu) {
                    FavoriteStar(viewModel: viewModel)
                }
                .multiActionSheet(isPresented: $appState.showingSortMenu) {
                    Group {
                        FilesSortRow(viewModel: viewModel)
                        RepliesSortRow(viewModel: viewModel)
                    }
                }
            }
        }
        .task {
            viewModel.load()
        }
    }

    var sortingButton: some View {
        Button(action: {
            withAnimation {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                appState.showingSortMenu = true

            }
        }, label: {
            Image(systemName: sorting ?
                  "arrow.up.and.down.righttriangle.up.righttriangle.down.fill" :
                    "arrow.up.and.down.righttriangle.up.righttriangle.down")
        })
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
        CatalogView(viewModel: CatalogView.CatalogViewModel(boardName: "fit"))
            .environmentObject(AppState())
    }
}
#endif
