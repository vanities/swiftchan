import SwiftUI
import SwiftData

struct SavedRepliesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SavedReply.savedAt, order: .reverse) private var replies: [SavedReply]
    @State private var search = ""
    @State private var errorMessage: String?

    private var matches: [SavedReply] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return replies.filter {
            query.isEmpty || "\($0.boardName) \($0.postID) \($0.threadTitle) \($0.text)".localizedStandardContains(query)
        }
    }

    var body: some View {
        List {
            if replies.isEmpty {
                ContentUnavailableView("No Saved Replies", systemImage: "bookmark",
                                       description: Text("Use a post’s ••• menu to save its text and a link back to it."))
            } else if matches.isEmpty {
                ContentUnavailableView.search(text: search)
            }
            ForEach(matches) { reply in
                VStack(alignment: .leading, spacing: 10) {
                    Text("/\(reply.boardName)/ · #\(reply.postID)")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(reply.threadTitle).font(.headline)
                    Text(reply.text.isEmpty ? "Media-only post" : reply.text)
                        .textSelection(.enabled)
                    HStack {
                        NavigationLink("Open Post") {
                            ThreadView(boardName: reply.boardName, postNumber: reply.threadID, postID: reply.postID)
                        }
                        .accessibilityIdentifier("Open Saved Reply \(reply.postID)")
                        Spacer()
                        ShareLink(item: reply.url) { Image(systemName: "square.and.arrow.up") }
                            .accessibilityLabel("Share saved reply")
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.vertical, 6)
                .swipeActions {
                    Button("Remove", role: .destructive) {
                        context.delete(reply)
                        do { try context.save() } catch { errorMessage = error.localizedDescription }
                    }
                }
            }
        }
        .navigationTitle("Saved Replies")
        .searchable(text: $search, prompt: "Search saved text, board, or post number")
        .alert("Couldn’t Update Saved Replies", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }
}
