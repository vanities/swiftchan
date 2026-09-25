import SwiftUI
import SwiftData

struct AddRecurringFavoriteSheet: View {
    var onSave: (() -> Void)?
    private let favorite: RecurringFavorite?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var boardName: String
    @State private var searchPattern: String
    @State private var displayName: String
    @State private var errorMessage: String?

    init(searchPattern: String = "", boardName: String = "", displayName: String = "", favorite: RecurringFavorite? = nil, onSave: (() -> Void)? = nil) {
        self.favorite = favorite
        self.onSave = onSave
        _boardName = State(initialValue: favorite?.boardName ?? boardName)
        _searchPattern = State(initialValue: favorite?.searchPattern ?? searchPattern)
        _displayName = State(initialValue: favorite?.displayName ?? displayName)
    }

    private var draft: RecurringFavoriteDraft? {
        RecurringFavoriteDraft(boardName: boardName, searchPattern: searchPattern, displayName: displayName)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Board") {
                        TextField("Board", text: $boardName, prompt: Text("biz"))
                            .multilineTextAlignment(.trailing)
                            .accessibilityIdentifier("General Board")
                    }
                    LabeledContent("General tag") {
                        TextField("General tag", text: $searchPattern, prompt: Text("/pmg/"))
                            .multilineTextAlignment(.trailing)
                            .accessibilityIdentifier("General Tag")
                    }
                } header: {
                    Text("Find the general")
                } footer: {
                    Text("For Precious Metals General, enter biz and /pmg/. Slashes are optional.")
                }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                Section {
                    TextField("Name (optional)", text: $displayName, prompt: Text("Precious Metals General"), axis: .vertical)
                        .lineLimit(1...3)
                        .accessibilityIdentifier("General Name")
                } header: {
                    Text("Name (optional)")
                } footer: {
                    if let draft {
                        Text("Tap this favorite to find current threads with \(draft.searchPattern) in their title on /\(draft.boardName)/.")
                    } else {
                        Text("Give it a name you’ll recognize in Favorites. It follows new threads as older ones expire.")
                    }
                }
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
            .navigationTitle(favorite == nil ? "Follow a General" : "Edit General")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(favorite == nil ? "Follow" : "Save", action: save)
                        .disabled(draft == nil)
                        .accessibilityIdentifier("Save General")
                }
            }
        }
    }

    private func save() {
        guard let draft else { return }
        do {
            _ = try draft.save(in: modelContext, editing: favorite)
            onSave?()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
