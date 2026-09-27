import SwiftUI
import SafariServices

struct ReplyDraftSheet: View {
    let board: String
    let threadID: Int
    let postID: Int
    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    @State private var showWebsite = false
    private let key: String
    private let defaults: UserDefaults?

    init(board: String, threadID: Int, postID: Int) {
        self.board = board
        self.threadID = threadID
        self.postID = postID
        key = "replyDraft.\(board).\(threadID)"
        defaults = ProcessInfo.processInfo.arguments.contains("--ui-testing") ? nil : .standard
        let quote = ">>\(postID)"
        let saved = defaults?.string(forKey: key) ?? ""
        _text = State(initialValue: saved.components(separatedBy: .newlines).contains(quote)
                      ? saved : saved + (saved.isEmpty ? "" : "\n") + quote + "\n")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $text).frame(minHeight: 180).accessibilityIdentifier("Reply Draft")
                } header: { Text("Reply to /\(board)/ #\(postID)") } footer: {
                    Text("Your draft stays on this device. Copy it, then paste into 4chan’s reply box. Add attachments and complete CAPTCHA on the site.")
                }
                Button("Copy Draft & Open 4chan", systemImage: "arrow.up.right.square") {
                    UIPasteboard.general.string = text
                    showWebsite = true
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button("Discard Draft", role: .destructive) {
                    defaults?.removeObject(forKey: key)
                    dismiss()
                }
            }
            .navigationTitle("Reply Draft")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .onChange(of: text) { defaults?.set(text, forKey: key) }
            .sheet(isPresented: $showWebsite) {
                PostingWebsite(url: URL(string: "https://boards.4chan.org/\(board)/thread/\(threadID)#p\(postID)")!)
            }
        }
    }
}

private struct PostingWebsite: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController { SFSafariViewController(url: url) }
    func updateUIViewController(_ controller: SFSafariViewController, context: Context) { }
}
