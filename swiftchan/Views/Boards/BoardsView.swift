//
//  BoardsView.swift
//  swiftchan
//
//  Created on 10/30/20.
//

import SwiftUI
import FourChan

struct BoardsView: View {
    @AppStorage("showNSFWBoards") private var showNSFWBoards: Bool = false
    @AppStorage("favoriteBoards") private var favoriteBoards: [String] = []
    @Environment(AppState.self) private var appState

    @State var boardsViewModel = BoardsViewModel()

    @State private var searchText: String = ""
    @State private var presentedNavigation = NavigationPath()

    @ViewBuilder
    var body: some View {
        switch boardsViewModel.state {
        case .initial:
            BoardsLoadingView(viewModel: boardsViewModel)
                .task {
                    await boardsViewModel.load()
                }
        case .loading:
            BoardsLoadingView(viewModel: boardsViewModel)
        case .loaded:
            NavigationStack(path: $presentedNavigation) {
                ZStack {
                    ScrollView(.vertical, showsIndicators: true) {
                        LazyVStack(alignment: .leading, spacing: Constants.gridSpacing) {
                            if searchText.isEmpty {
                                BoardSection(
                                    headerText: Constants.favoritesText,
                                    list: boardsViewModel.getFavoriteBoards(favoriteBoards)
                                )
                            }
                            BoardSection(
                                headerText: Constants.allText,
                                list: boardsViewModel.getFilteredBoards(searchText: searchText)
                            )
                        }
                    }
                    .searchable(text: $searchText)
                }
                .buttonStyle(.plain)
                .navigationBarTitle(Constants.title)
                .navigationDestination(for: String.self) { value in
                    CatalogView(boardName: value)
                }
                .navigationDestination(for: ThreadDestination.self) { dest in
                    ThreadView(boardName: dest.board, postNumber: dest.id)
                }
            }
            .onOpenURL { url in
                switch Deeplinker.getType(url: url) {
                case .board(let name):
                    presentedNavigation.append(name)
                case .thread(let board, let id):
                    presentedNavigation.append(ThreadDestination(board: board, id: Int(id) ?? 0))
                default:
                    break
                }
            }
        case .error:
            VStack {
                Image(systemName: Constants.refreshIcon)
                    .frame(width: 25, height: 25)
                Text("Error loading boards, Tap to retry.")
            }.onTapGesture {
                Task {
                    await boardsViewModel.load()
                }
            }
            .foregroundColor(Color.red)
        }
    }

    struct Constants {
        static let favoritesText = "favorites"
        static let allText = "all"
        static let title = "4chan"
        static let refreshIcon = "arrow.clockwise"
        static let gridSpacing: CGFloat = 1
    }
}

struct BoardsLoadingView: View {
    let viewModel: BoardsViewModel
    @State private var downloadPercentage: Int = 0

    var body: some View {
        VStack(spacing: 15) {
            Text("Loading Boards")
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
    BoardsView()
        .environment(AppState())
}
#endif
