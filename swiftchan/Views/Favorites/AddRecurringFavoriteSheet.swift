//
//  AddRecurringFavoriteSheet.swift
//  swiftchan
//
//  Sheet for confirming and saving a recurring favorite.
//

import SwiftUI
import SwiftData

struct AddRecurringFavoriteSheet: View {
    let searchPattern: String
    let boardName: String
    var onSave: (() -> Void)?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var displayName: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Board")
                        Spacer()
                        Text("/\(boardName)/")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Search Pattern")
                        Spacer()
                        Text(searchPattern)
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    TextField("Display Name (optional)", text: $displayName)
                } footer: {
                    Text("A custom name to display instead of the search pattern.")
                }

                Section {
                    Text("This will save the search pattern as a recurring favorite. When you tap it in Favorites, it will search /\(boardName)/ for threads matching \"\(searchPattern)\" and open the most recent one.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Save Recurring")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRecurringFavorite()
                        onSave?()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func saveRecurringFavorite() {
        // Wrap pattern in slashes if not already wrapped
        var pattern = searchPattern
        if !pattern.hasPrefix("/") {
            pattern = "/" + pattern
        }
        if !pattern.hasSuffix("/") {
            pattern = pattern + "/"
        }

        let favorite = RecurringFavorite(
            searchPattern: pattern,
            boardName: boardName,
            displayName: displayName.isEmpty ? nil : displayName
        )
        modelContext.insert(favorite)
    }
}

#if DEBUG
#Preview {
    AddRecurringFavoriteSheet(searchPattern: "ptg", boardName: "g")
        .modelContainer(for: RecurringFavorite.self, inMemory: true)
}
#endif
