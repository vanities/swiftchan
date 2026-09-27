import SwiftUI

struct PostFiltersView: View {
    private enum Input: Hashable { case board, pattern }
    @FocusState private var focused: Input?
    @State private var board = ""
    @State private var pattern = ""
    @State private var field = PostFilterRule.Field.keyword
    @State private var action = PostFilterRule.Action.hide
    private let store = PostFilterStore.shared

    private var valid: Bool {
        !pattern.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && (board.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || Deeplinker.normalizedBoard(board) != nil)
    }

    var body: some View {
        Form {
            Section("Add Rule") {
                TextField("Board (blank for all)", text: $board).accessibilityIdentifier("Filter Board")
                    .focused($focused, equals: .board)
                Picker("Match", selection: $field) { ForEach(PostFilterRule.Field.allCases, id: \.self) { Text($0.rawValue) } }
                TextField("Text to match", text: $pattern).accessibilityIdentifier("Filter Pattern")
                    .focused($focused, equals: .pattern)
                Picker("Action", selection: $action) { ForEach(PostFilterRule.Action.allCases, id: \.self) { Text($0.rawValue) } }
                Button("Add Filter") {
                    store.add(PostFilterRule(board: Deeplinker.normalizedBoard(board), field: field,
                                             pattern: pattern.trimmingCharacters(in: .whitespacesAndNewlines), action: action))
                    pattern = ""
                    focused = nil
                }.disabled(!valid)
            }
            .textInputAutocapitalization(.never).autocorrectionDisabled()
            Section {
                ForEach(store.rules) { rule in
                    VStack(alignment: .leading) {
                        Text("\(rule.action.rawValue): \(rule.pattern)")
                        Text("\(rule.board.map { "/\($0)/" } ?? "All boards") · \(rule.field.rawValue)")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .swipeActions { Button("Delete", role: .destructive) { store.remove(rule) } }
                }
            } header: { Text("Active Rules") } footer: {
                Text("Matches ignore case. Poster IDs match exactly; other fields match part of the text. Hide takes priority over highlight. Swipe a rule to delete it. Rules stay on this device.")
            }
        }
        .navigationTitle("Filters & Highlights")
    }
}
