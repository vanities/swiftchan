//
//  CatalogView.swift
//  swiftchan
//
//  Created on 10/31/20.
//

import SwiftUI
import FourChan
import SpriteKit

struct CatalogView: View {
    @AppStorage("hideTabOnBoards") var hideTabOnBoards = false

    @Environment(AppState.self) var appState

    var boardName: String
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
            CatalogLoadingView(viewModel: catalogViewModel)
                .task {
                    await catalogViewModel.load()
                }
        case .loading:
            CatalogLoadingView(viewModel: catalogViewModel)
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
            .toolbar(hideTabOnBoards ? .hidden : .automatic, for: .tabBar)
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

struct CatalogLoadingView: View {
    let viewModel: CatalogViewModel
    @State private var downloadPercentage: Int = 0

    var body: some View {
        VStack(spacing: 15) {
            Text("Loading /\(viewModel.boardName)/")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text(viewModel.progressText.isEmpty ? "Preparing..." : viewModel.progressText)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text("\(downloadPercentage)%")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.accentColor)

            ProgressView(value: Double(downloadPercentage), total: 100.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .frame(maxWidth: 250)
        }
        .padding()
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            downloadPercentage = Int(viewModel.downloadProgress.fractionCompleted * 100)
        }
    }
}

#if DEBUG
#Preview {
    CatalogView(boardName: "fit")
        .environment(AppState())
}
#endif
