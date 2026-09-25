import SwiftUI

struct HiddenPostsView: View {
    @State private var showRestoreAll = false
    @State private var search = ""
    private let store = HiddenPostStore.shared

    private var matchingItems: [HiddenPost] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return store.items.filter {
            query.isEmpty || "\($0.boardName) \($0.postID) \($0.label)".localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        Group {
            if store.items.isEmpty {
                ContentUnavailableView("Nothing Hidden", systemImage: "eye",
                                       description: Text("Posts and threads you hide appear here. You can restore them at any time."))
            } else if matchingItems.isEmpty {
                ContentUnavailableView.search(text: search)
            } else {
                List(matchingItems) { item in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.label).lineLimit(2)
                            Text("/\(item.boardName)/ · #\(item.postID)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Restore") { store.restore(item) }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("Restore Hidden \(item.id)")
                    }
                    .swipeActions {
                        Button("Restore", systemImage: "eye") { store.restore(item) }
                            .tint(.accentColor)
                    }
                }
            }
        }
        .navigationTitle("Hidden Posts & Threads")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $search, prompt: "Board, title, or post number")
        .toolbar {
            if !store.items.isEmpty {
                Button("Restore All") { showRestoreAll = true }
            }
        }
        .confirmationDialog("Restore all hidden posts and threads?", isPresented: $showRestoreAll, titleVisibility: .visible) {
            Button("Restore All") { store.restoreAll() }
        }
    }
}
