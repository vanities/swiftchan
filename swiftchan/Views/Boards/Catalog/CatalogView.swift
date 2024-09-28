//
//  CatalogView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI
import FourChan
import SpriteKit

struct CatalogView: View {
    var boardName: String
    @Environment(AppState.self) var appState
    @State var catalogViewModel: CatalogViewModel

    @State var searchText: String = ""
    @State var isShowingMenu: Bool = false

    let columns = [
        GridItem(.flexible(), spacing: 0, alignment: .top),
        GridItem(.flexible(), spacing: 0, alignment: .top)
    ]

    var scene: SKScene {
        let scene = SnowScene()
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        return scene
    }

    init(boardName: String) {
        self.boardName = boardName
        self._catalogViewModel = State(
            wrappedValue: CatalogViewModel(boardName: boardName)
        )
    }

    @ViewBuilder
    var body: some View {
        @Bindable var appState = appState
        let filteredPosts = catalogViewModel.getFilteredPosts(searchText: searchText)

        switch catalogViewModel.state {
        case .initial:
            ProgressView()
                .task {
                    await catalogViewModel.load()
                }
        case .loading:
            ProgressView()
        case .loaded:
            ScrollView(.vertical, showsIndicators: true) {
                LazyVGrid(
                    columns: columns,
                    alignment: .center,
                    spacing: 0
                ) {
                    ForEach(filteredPosts) { post in
                        if !post.post.isHidden(boardName: boardName) {
                            NavigationLink(value: post) {
                                OPView(
                                    boardName: boardName,
                                    post: post
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .onScrollingChange(onScrollingDown: {
                    withAnimation(.easeIn) {
                        appState.showNavAndTab = false
                    }
                }, onScrollingUp: {
                    withAnimation(.easeIn) {
                        appState.showNavAndTab = true
                    }
                })
            }
            .overlay {
                if Date.isChristmas() {
                    SpriteView(scene: scene, options: [.allowsTransparency])
                        .ignoresSafeArea()
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .disabled(true)
                }
            }
            .onAppear {
                catalogViewModel.prefetch()
            }
            .onDisappear {
                catalogViewModel.stopPrefetching()
            }
            .navigationBarTitle(boardName)
            .navigationBarItems(
                trailing: settingsButton

            )
            .navigationDestination(for: SwiftchanPost.self) { post in
                ThreadView(
                    boardName: post.boardName,
                    postNumber: post.post.id
                )
            }
            .searchable(text: $searchText)
            .refreshable {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                Task {
                    await catalogViewModel.load()
                    catalogViewModel.prefetch()
                }
            }
            .sheet(isPresented: $appState.showingCatalogMenu) {
                Group {
                    FavoriteStar(viewModel: catalogViewModel)
                    FilesSortRow(viewModel: catalogViewModel)
                    RepliesSortRow(viewModel: catalogViewModel)
                }
                .presentationDetents([.fraction(0.4)])
            }
            .toolbar(appState.showNavAndTab ? .visible : .hidden, for: .navigationBar)
            .toolbar(appState.showNavAndTab ? .visible : .hidden, for: .tabBar)
        case .error:
            VStack {
                Image(systemName: Constants.refreshIcon)
                    .frame(width: 25, height: 25)
                Text("Error loading catalog, Tap to retry.")
            }.onTapGesture {
                Task {
                    await catalogViewModel.load()
                    catalogViewModel.prefetch()
                }
            }
            .foregroundColor(Color.red)
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

    struct Constants {
        static let refreshIcon = "arrow.clockwise"
    }
}

#if DEBUG
#Preview {
    CatalogView(boardName: "fit")
        .environment(AppState())
}
#endif
