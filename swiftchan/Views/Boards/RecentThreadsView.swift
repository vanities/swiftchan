import SwiftUI

struct RecentThreadsView: View {
    @State private var search = ""
    @State private var confirmClear = false
    @AppStorage("rememberThreadPositions") private var rememberProgress = true
    private let store = ThreadReadingStore.shared

    private var matches: [RecentThread] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return store.recentThreads.filter {
            query.isEmpty || "\($0.board) \($0.threadID) \($0.title)".localizedStandardContains(query)
        }
    }

    var body: some View {
        List {
            if store.recentThreads.isEmpty {
                ContentUnavailableView("No Recent Threads", systemImage: "clock",
                                       description: Text("Threads appear here when Remember Reading Progress is enabled."))
            } else if matches.isEmpty {
                ContentUnavailableView.search(text: search)
            }
            Section {
                ForEach(matches) { thread in
                    NavigationLink {
                        ThreadView(boardName: thread.board, postNumber: thread.threadID)
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(thread.title).font(.headline).lineLimit(2)
                            Text("/\(thread.board)/ · #\(thread.threadID)").font(.caption).foregroundStyle(.secondary)
                            Text(thread.progress.updatedAt, style: .relative).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityIdentifier("Recent Thread \(thread.id)")
                    .swipeActions {
                        Button("Remove", role: .destructive) { store.remove(thread) }
                    }
                }
            } footer: {
                Text(rememberProgress
                     ? "Your last 300 threads. Removing entries also clears their saved reading positions."
                     : "Remember Reading Progress is off. New threads won’t be added; existing entries stay until you remove them.")
            }
        }
        .navigationTitle("Recent Threads")
        .searchable(text: $search, prompt: "Search title, board, or thread number")
        .toolbar {
            Button("Clear", role: .destructive) { confirmClear = true }
                .disabled(store.recentThreads.isEmpty)
                .accessibilityIdentifier("Clear Recent Threads")
        }
        .confirmationDialog("Clear recent threads and saved reading progress?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Clear All", role: .destructive) { store.clear() }
        }
    }
}
