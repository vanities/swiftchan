//
//  FavoritesView.swift
//  swiftchan
//
//  View for displaying saved favorite threads.
//

import SwiftUI
import SwiftData

enum FavoriteSortOption: String, CaseIterable {
    case savedAt = "Date Saved"
    case boardName = "Board"
    case replyCount = "Replies"
    case imageCount = "Images"
}

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \FavoriteThread.savedAt, order: .reverse) private var favorites: [FavoriteThread]

    @State private var presentedNavigation = NavigationPath()
    @State private var searchText = ""
    @State private var sortOption: FavoriteSortOption = .savedAt
    @State private var sortAscending = false
    @State private var selectedBoard: String?

    private var availableBoards: [String] {
        Array(Set(favorites.map { $0.boardName })).sorted()
    }

    private var filteredAndSortedFavorites: [FavoriteThread] {
        var result = favorites

        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { favorite in
                favorite.title.localizedCaseInsensitiveContains(searchText) ||
                favorite.boardName.localizedCaseInsensitiveContains(searchText) ||
                String(favorite.threadId).contains(searchText)
            }
        }

        // Filter by board
        if let board = selectedBoard {
            result = result.filter { $0.boardName == board }
        }

        // Sort
        result.sort { a, b in
            let comparison: Bool
            switch sortOption {
            case .savedAt:
                comparison = a.savedAt > b.savedAt
            case .boardName:
                comparison = a.boardName < b.boardName
            case .replyCount:
                comparison = a.replyCount > b.replyCount
            case .imageCount:
                comparison = a.imageCount > b.imageCount
            }
            return sortAscending ? !comparison : comparison
        }

        return result
    }

    var body: some View {
        NavigationStack(path: $presentedNavigation) {
            Group {
                if favorites.isEmpty {
                    emptyState
                } else {
                    favoritesList
                }
            }
            .navigationTitle("Favorites")
            .searchable(text: $searchText, prompt: "Search favorites")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    sortMenu
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    filterMenu
                }
            }
            .navigationDestination(for: ThreadDestination.self) { dest in
                ThreadView(boardName: dest.board, postNumber: dest.id)
            }
        }
    }

    private var sortMenu: some View {
        Menu {
            Picker("Sort By", selection: $sortOption) {
                ForEach(FavoriteSortOption.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }

            Divider()

            Button {
                sortAscending.toggle()
            } label: {
                Label(
                    sortAscending ? "Ascending" : "Descending",
                    systemImage: sortAscending ? "arrow.up" : "arrow.down"
                )
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }

    private var filterMenu: some View {
        Menu {
            Button {
                selectedBoard = nil
            } label: {
                HStack {
                    Text("All Boards")
                    if selectedBoard == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }

            if !availableBoards.isEmpty {
                Divider()

                ForEach(availableBoards, id: \.self) { board in
                    Button {
                        selectedBoard = board
                    } label: {
                        HStack {
                            Text("/\(board)/")
                            if selectedBoard == board {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        } label: {
            Image(systemName: selectedBoard != nil ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No Favorites Yet")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Tap the heart icon in a thread to save it here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private var favoritesList: some View {
        List {
            if filteredAndSortedFavorites.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                ForEach(filteredAndSortedFavorites) { favorite in
                    Button {
                        presentedNavigation.append(
                            ThreadDestination(board: favorite.boardName, id: favorite.threadId)
                        )
                    } label: {
                        FavoriteThreadRow(favorite: favorite)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: deleteFavorites)
            }
        }
        .listStyle(.plain)
    }

    private func deleteFavorites(offsets: IndexSet) {
        withAnimation {
            let toDelete = offsets.map { filteredAndSortedFavorites[$0] }
            for favorite in toDelete {
                modelContext.delete(favorite)
            }
        }
    }
}

#if DEBUG
#Preview {
    FavoritesView()
        .environment(AppState())
        .modelContainer(for: FavoriteThread.self, inMemory: true)
}
#endif
