//
//  CatalogView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI
import FourChan

struct CatalogView: View {
    enum LoadingState {
        case loading
        case loaded
    }

    @EnvironmentObject var appState: AppState
    @StateObject var viewModel: CatalogViewModel

    @State var searchText: String = ""
    @State var pullToRefreshShowing: Bool = false
    @State var state: LoadingState = .loading
    @State var isShowingMenu: Bool = false

    let columns = [
        GridItem(.flexible(), spacing: 0, alignment: .top),
        GridItem(.flexible(), spacing: 0, alignment: .top)
    ]

    var navigationCentering: CGFloat {
        return CGFloat(20 + (self.viewModel.boardName.count * 5))
    }

    init(_ boardName: String) {
        self._viewModel = StateObject(wrappedValue: CatalogView.CatalogViewModel(boardName: boardName))
    }

    var filteredPosts: [SwiftchanPost] {
        if searchText.isEmpty {
            return viewModel.sortedPosts
        } else {
            return viewModel.sortedPosts.compactMap { swiftChanPost -> SwiftchanPost? in
                let commentAndSubject = "\(swiftChanPost.post.com?.clean.lowercased() ?? "") \(swiftChanPost.post.sub?.clean.lowercased() ?? "")"

                return commentAndSubject.contains(searchText.lowercased()) ? swiftChanPost : nil
            }
        }
    }

    @ViewBuilder
    var body: some View {
        switch state {
        case .loading:
            ActivityIndicator()
                .onChange(of: viewModel.posts.count) { numOfComments in
                    if numOfComments > 0 {
                        state = .loaded
                    }
                }
        case .loaded:
            ScrollView(.vertical, showsIndicators: true) {
                LazyVGrid(columns: columns,
                          alignment: .center,
                          spacing: 0) {
                    ForEach(filteredPosts, id: \.post.id) { post in
                        OPView(boardName: viewModel.boardName,
                               post: post.post,
                               comment: post.comment)
                            .accessibilityIdentifier(AccessibilityIdentifiers.opButton(viewModel.sortedPosts.firstIndex(where: { $0.post == post.post}) ?? 0))
                    }
                }
                          .pullToRefresh(isRefreshing: $pullToRefreshShowing) {
                              state = .loading
                              let softVibrate = UIImpactFeedbackGenerator(style: .soft)
                              softVibrate.impactOccurred()
                              viewModel.load {
                                  pullToRefreshShowing = false
                                  state = .loaded
                              }
                          }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarTitle(viewModel.boardName)
            .navigationBarItems(
                trailing:
                    HStack {
                        Button(action: {
                            withAnimation {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                appState.showingSortMenu = true

                            }
                        }, label: {
                            Image(systemName: "slider.horizontal.3")
                        })
                        Button(action: {
                            withAnimation {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                appState.showingCatalogMenu = true

                            }
                        }, label: {
                            Image(systemName: "ellipsis")
                        })
                    }
            )
            .searchable(text: $searchText)
            .multiActionSheet(isPresented: $appState.showingCatalogMenu) {
                FavoriteStar(viewModel: viewModel)
            }
            .multiActionSheet(isPresented: $appState.showingSortMenu) {
                RepliesSort(viewModel: viewModel)
            }
        }
    }
}

struct CatalogView_Previews: PreviewProvider {
    static var previews: some View {
        CatalogView("fit")
            .environmentObject(AppState())
    }
}
