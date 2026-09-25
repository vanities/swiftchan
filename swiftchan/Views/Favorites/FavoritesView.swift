//
//  FavoritesView.swift
//  swiftchan
//
//  View for displaying saved favorite threads.
//

import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \FavoriteThread.savedAt, order: .reverse) private var favorites: [FavoriteThread]
    @Query(sort: \RecurringFavorite.createdAt, order: .reverse) private var recurringFavorites: [RecurringFavorite]

    @State private var presentedNavigation = NavigationPath()
    @State private var searchText = ""
    @State private var sortOption: FavoriteSortOption = .savedAt
    @State private var sortAscending = false
    @State private var selectedBoard: String?
    @State private var selectedRecurring: RecurringFavorite?
    @State private var recurringViewModel = RecurringFavoriteViewModel()

    private var query: FavoritesQuery {
        FavoritesQuery(searchText: searchText, boardName: selectedBoard, sort: sortOption, ascending: sortAscending)
    }

    private var availableBoards: [String] {
        FavoritesQuery.availableBoards(saved: favorites, recurring: recurringFavorites)
    }

    private var filteredAndSortedFavorites: [FavoriteThread] {
        query.savedThreads(favorites)
    }

    private var isEmpty: Bool {
        favorites.isEmpty && recurringFavorites.isEmpty
    }

    var body: some View {
        NavigationStack(path: $presentedNavigation) {
            Group {
                if isEmpty {
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
            .sheet(item: $selectedRecurring) { recurring in
                RecurringMatchSheet(
                    favorite: recurring,
                    viewModel: recurringViewModel,
                    onSelect: { post in
                        presentedNavigation.append(
                            ThreadDestination(board: post.boardName, id: post.post.no)
                        )
                    }
                )
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

    private var filteredRecurringFavorites: [RecurringFavorite] {
        query.recurringThreads(recurringFavorites)
    }

    private var favoritesList: some View {
        List {
            if !filteredRecurringFavorites.isEmpty {
                Section("Recurring Threads") {
                    ForEach(filteredRecurringFavorites) { recurring in
                        Button {
                            selectedRecurring = recurring
                        } label: {
                            RecurringFavoriteRow(favorite: recurring)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteRecurringFavorites)
                }
            }

            if !filteredAndSortedFavorites.isEmpty {
                Section("Saved Threads") {
                    ForEach(filteredAndSortedFavorites) { favorite in
                        Button {
                            presentedNavigation.append(
                                ThreadDestination(board: favorite.boardName, id: favorite.threadId)
                            )
                        } label: {
                            FavoriteThreadRow(favorite: favorite)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteFavorites)
                }
            }

            if filteredAndSortedFavorites.isEmpty && filteredRecurringFavorites.isEmpty {
                if !searchText.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    ContentUnavailableView("No Favorites on This Board", systemImage: "heart.slash",
                                           description: Text("Choose All Boards to see your other favorites."))
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func deleteRecurringFavorites(offsets: IndexSet) {
        withAnimation {
            let toDelete = offsets.map { filteredRecurringFavorites[$0] }
            for recurring in toDelete {
                modelContext.delete(recurring)
            }
        }
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
        .modelContainer(for: [FavoriteThread.self, RecurringFavorite.self], inMemory: true)
}
#endif
