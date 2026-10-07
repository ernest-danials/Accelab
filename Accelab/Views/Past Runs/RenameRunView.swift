//
//  RenameRunView.swift
//  Accelab
//

import SwiftUI
import SwiftData

/// Names a saved run. A screen of its own rather than an alert: in landscape the keyboard leaves an
/// alert with a text field too little room, and it gets cut off.
struct RenameRunView: View {
    let run: SavedRun

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @FocusState private var isNameFocused: Bool

    init(run: SavedRun) {
        self.run = run
        self._name = State(initialValue: run.name ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(run.defaultTitle, text: $name)
                        .focused($isNameFocused)
                        .submitLabel(.done)
                        .onSubmit(save)
                } footer: {
                    Text("Leave it empty to go back to the default name.")
                }
            }
            .navigationTitle("Rename Run")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm, action: save)
                }
            }
            .onAppear {
                self.isNameFocused = true
            }
        }
    }

    private func save() {
        // An empty name goes back to the one made from the method.
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        run.name = trimmedName.isEmpty ? nil : trimmedName
        dismiss()
    }
}

extension View {
    /// Shows `RenameRunView` for the run in `run`, which is set back to `nil` once it closes.
    func renameRunCover(for run: Binding<SavedRun?>) -> some View {
        fullScreenCover(item: run) { run in
            RenameRunView(run: run)
        }
    }
}
