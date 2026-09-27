import SwiftUI
import SwiftData

struct ThreadWatcherView: View {
    @Query(sort: \FavoriteThread.savedAt, order: .reverse) private var favorites: [FavoriteThread]
    @Environment(\.scenePhase) private var scenePhase
    @State private var watcher = ThreadWatcher.shared

    private var targets: [WatchTarget] { favorites.map { WatchTarget(board: $0.boardName, threadID: $0.threadId) } }

    var body: some View {
        List {
            if favorites.isEmpty {
                ContentUnavailableView("No Watched Threads", systemImage: "eye",
                                       description: Text("Save a thread with the heart button to watch it here."))
            }
            ForEach(favorites) { favorite in
                let key = "\(favorite.boardName)/\(favorite.threadId)"
                NavigationLink {
                    ThreadView(boardName: favorite.boardName, postNumber: favorite.threadId)
                } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(favorite.title.isEmpty ? "Thread #\(favorite.threadId)" : favorite.title).lineLimit(2)
                        Text("/\(favorite.boardName)/ · \(status(key, favorite: favorite))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            Section {} footer: {
                Text("Pull to check saved threads. Checks run while this screen is open, at most once every 30 seconds. Unread counts use saved reading progress; unavailable threads may still be in an archive.")
            }
        }
        .navigationTitle("Thread Watcher")
        .overlay(alignment: .top) { if watcher.refreshing { ProgressView("Checking threads…").padding().background(.regularMaterial) } }
        .task { await watcher.refresh(targets) }
        .refreshable { await watcher.refresh(targets) }
        .onDisappear { watcher.cancel() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { watcher.cancel() }
        }
    }

    private func status(_ key: String, favorite: FavoriteThread) -> String {
        if let error = watcher.errors[key] { return error }
        guard let result = watcher.results[key] else { return "Not checked" }
        if result.missing { return "Unavailable" }
        let read = ThreadReadingStore.shared.progress(board: favorite.boardName, threadID: favorite.threadId)?.highestReadID
        let count = result.unread(after: read).map { "\($0) unread" } ?? "\(result.replyIDs.count) replies"
        return result.archived ? "Archived · \(count)" : count
    }
}
