//
//  PastRunsView.swift
//  Accelab
//

import SwiftUI
import SwiftData

struct PastRunsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \SavedRun.date, order: .reverse) private var runs: [SavedRun]

    @State private var runBeingRenamed: SavedRun? = nil

    var body: some View {
        NavigationStack {
            List {
                ForEach(runs) { run in
                    NavigationLink {
                        PastRunDetailView(run: run)
                    } label: {
                        row(for: run)
                    }
                    .contextMenu {
                        Button("Rename", systemImage: "pencil") { self.runBeingRenamed = run }
                        Button("Delete", systemImage: "trash", role: .destructive) { modelContext.delete(run) }
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        modelContext.delete(runs[index])
                    }
                }
            }
            .overlay {
                if runs.isEmpty {
                    ContentUnavailableView("No Past Runs", systemImage: "clock.arrow.circlepath", description: Text("Runs you finish are saved here."))
                }
            }
            .renameRunCover(for: $runBeingRenamed)
            .navigationTitle("Past Runs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func row(for run: SavedRun) -> some View {
        HStack(spacing: 12) {
            // The symbol the run's own page opens with, so the list reads as the labs done. The method is in the caption.
            Image(systemName: run.imageName)
                .customFont(.title3, weight: .medium)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.accent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(run.title)
                    .customFont(.headline)

                Text(run.caption)
                    .customFont(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    PastRunsView()
        .modelContainer(for: SavedRun.self, inMemory: true)
}
