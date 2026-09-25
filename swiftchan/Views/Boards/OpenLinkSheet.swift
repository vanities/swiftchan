import SwiftUI

struct OpenLinkSheet: View {
    let onOpen: (Deeplinker.Deeplink) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var showError = false
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://boards.4chan.org/po/", text: $text)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.go)
                        .focused($focused)
                        .onSubmit(open)
                        .accessibilityIdentifier("Open Link URL")
                    PasteButton(payloadType: String.self) { values in
                        if let value = values.first { text = value }
                    }
                } header: {
                    Text("Board or thread URL")
                } footer: {
                    Text("Paste a 4chan or 4channel link to open it here.")
                }
                if showError {
                    Text("Enter a valid board or thread link from boards.4chan.org or boards.4channel.org.")
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("Open Link Error")
                }
            }
            .navigationTitle("Open Link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Open", action: open)
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityIdentifier("Open Link Confirm")
                }
            }
            .onChange(of: text) { showError = false }
            .task { focused = true }
        }
        .presentationDetents([.medium, .large])
    }

    private func open() {
        guard let link = Deeplinker.parse(text) else { showError = true; return }
        switch link {
        case .board, .thread:
            onOpen(link)
            dismiss()
        case .post:
            showError = true
        }
    }
}
