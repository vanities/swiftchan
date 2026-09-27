import SwiftUI

struct QuotePreviewSheet: View {
    let postID: Int
    @Environment(ThreadViewModel.self) private var model
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var path: [Int] = []

    var body: some View {
        NavigationStack(path: $path) {
            preview(postID)
                .navigationDestination(for: Int.self) { preview($0) }
        }
        .environment(\.openURL, OpenURLAction { url in
            if case .post(let id) = Deeplinker.getType(url: url), let number = Int(id) {
                path.append(number)
                return .handled
            }
            if let link = Deeplinker.getType(url: url), appState.openLink(link) {
                dismiss()
                return .handled
            }
            return .systemAction
        })
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func preview(_ number: Int) -> some View {
        Group {
            if let index = model.getPostIndexFromId(String(number)),
               !model.posts[index].isHidden(boardName: model.boardName), model.filterEffect(at: index) != .hide {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(model.posts[index].name ?? "Anonymous").font(.headline)
                        Text(model.comment(at: index)).textSelection(.enabled)
                        ShareLink("Share Post", item: model.postURL(number))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding()
                }
                .accessibilityIdentifier("Quote Preview \(number)")
            } else {
                ContentUnavailableView("Post Unavailable", systemImage: "text.bubble",
                                       description: Text("This post is hidden or is not in the loaded thread."))
            }
        }
        .navigationTitle("#\(number)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }.accessibilityIdentifier("Close Quote Preview")
            }
        }
    }
}
