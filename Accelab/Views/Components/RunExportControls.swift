//
//  RunExportControls.swift
//  Accelab
//

import SwiftUI

/// What a run exports and the Export menu, for a run just finished and for a saved one: the graph the
/// data is for, under a small caption, then every way out of the app in one prominent menu.
/// Place it in a row inside a `GlassEffectContainer`; `RunTableButton` previews the same columns.
struct RunExportControls: View {
    let data: RunData
    let csvURL: URL?
    /// The data as a text file Desmos can import.
    let desmosURL: URL?
    /// The columns that are copied and exported, as indices into the data's columns. `nil` until the user
    /// changes them, which means all of them and the files that were passed in.
    @Binding var selectedColumns: Set<Int>?
    /// The recorded clip, when the run was filmed in the app. `nil` for the sensor method, imported clips and saved runs.
    var videoURL: URL? = nil
    /// A photo of the last tracked frame with every point on it. `nil` for the sensor method, and
    /// until it has been drawn.
    var photoURL: URL? = nil
    let onRetryExport: () -> Void

    @State private var didCopyData: Bool = false
    /// The files written for `selectedColumns`, used instead of the ones passed in once the columns are changed.
    @State private var selectedCSVURL: URL? = nil
    @State private var selectedDesmosURL: URL? = nil

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Export data for")
                    .customFont(.caption, weight: .medium)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 12)

                graphMenu
            }

            if let csvURL = currentCSVURL {
                Menu {
                    Section("Desmos") {
                        Button("Copy Data", systemImage: "doc.on.doc", action: copyDataForDesmos)

                        if let desmosURL = currentDesmosURL {
                            ShareLink(item: desmosURL, preview: SharePreview("Accelab Data for Desmos", icon: Image(systemName: "doc.plaintext"))) {
                                Label("Text File", systemImage: "doc.plaintext")
                            }
                        }
                    }

                    Section {
                        ShareLink(item: csvURL, preview: SharePreview("Accelab Data", icon: Image(systemName: "tablecells"))) {
                            Label("CSV", systemImage: "tablecells")
                        }

                        if let videoURL {
                            ShareLink(item: videoURL, preview: SharePreview("Accelab Video", icon: Image(systemName: "video"))) {
                                Label("Video", systemImage: "video")
                            }
                        }

                        if let photoURL {
                            ShareLink(item: photoURL, preview: SharePreview("Accelab Photo", icon: Image(systemName: "photo"))) {
                                Label("Photo with Points", systemImage: "photo")
                            }
                        }
                    }
                } label: {
                    // One label whose content changes, so "Copied" animates in rather than replacing the button.
                    GlassIconLabel(systemImage: didCopyData ? "checkmark" : "square.and.arrow.up", title: didCopyData ? "Copied" : "Export", style: .prominent)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Export")
            } else {
                // Only reachable if writing the temp file failed.
                GlassIconButton(systemImage: "arrow.clockwise", title: "Retry Export", label: "Retry Export", style: .prominent, perform: retryExport)
            }
        }
        .task(id: didCopyData) {
            // Shows "Copied" for a moment, then offers the copy again.
            guard didCopyData, (try? await Task.sleep(for: .seconds(1.5))) != nil else { return }
            withAnimation { self.didCopyData = false }
        }
        .onChange(of: selectedColumns) {
            writeSelectedFiles()
        }
    }

    /// Which columns the table, the CSV and Desmos hold, chosen by the graph they're for: one choice for all
    /// three, so they always match. A graph keeps only its two columns, x first, so Desmos plots it as pasted.
    /// Columns at the bottom is for any other set; it stays open while columns are ticked, and the last column
    /// can't be taken away.
    private var graphMenu: some View {
        Menu {
            let headings = DataTableView.columnHeadings(for: data)
            let graphs = RunGraph.graphs(for: data)
            let selection = selectedColumns ?? Set(headings.indices)

            ForEach(graphs, id: \.self) { graph in
                Toggle(isOn: Binding(get: { selection == graph.columns }, set: { _ in self.selectedColumns = graph.columns })) {
                    Text(graph.title)
                    Text(graph.note)
                }
            }

            // A lab whose own graph is all of its data (distance against time) needs no "All Data".
            if !graphs.contains(where: { $0.columns.count == headings.count }) {
                Toggle(isOn: Binding(get: { selection.count == headings.count }, set: { _ in self.selectedColumns = Set(headings.indices) })) {
                    Text("All Data")
                    Text("Every column.")
                }
            }

            Divider()

            Menu {
                ForEach(headings.indices, id: \.self) { index in
                    Toggle(headings[index], isOn: Binding(get: { selection.contains(index) }, set: { isOn in
                        var columns = selection
                        if isOn { columns.insert(index) } else { columns.remove(index) }
                        self.selectedColumns = columns
                    }))
                    .disabled(selection == [index])
                }
                .menuActionDismissBehavior(.disabled)
            } label: {
                Label("Columns", systemImage: "checklist")
            }
        } label: {
            GlassIconLabel(systemImage: "chart.xyaxis.line", title: graphTitle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Export data for \(graphTitle)")
    }

    /// The chosen graph's name, so the row says what the exports are for.
    private var graphTitle: String {
        let allColumns = Set(CSVExporter.columns(for: data).indices)
        let chosen = selectedColumns ?? allColumns
        if let graph = RunGraph.graphs(for: data).first(where: { $0.columns == chosen }) { return graph.title }
        return chosen == allColumns ? "All Data" : "Custom"
    }

    private var currentCSVURL: URL? {
        selectedColumns == nil ? csvURL : selectedCSVURL
    }

    private var currentDesmosURL: URL? {
        selectedColumns == nil ? desmosURL : selectedDesmosURL
    }

    /// Rewrites both files together: writing the CSV removes every earlier export, the Desmos file with it.
    private func writeSelectedFiles() {
        guard let selectedColumns else { return }
        self.selectedCSVURL = CSVExporter.writeTempFile(for: data, columns: selectedColumns)
        self.selectedDesmosURL = CSVExporter.writeDesmosTempFile(for: data, columns: selectedColumns)
    }

    private func retryExport() {
        if selectedColumns == nil {
            onRetryExport()
        } else {
            writeSelectedFiles()
        }
    }

    /// Puts the data on the clipboard as rows Desmos turns into a table when pasted.
    private func copyDataForDesmos() {
        UIPasteboard.general.string = CSVExporter.makeDesmosText(from: data, columns: selectedColumns)
        Haptics.success()
        withAnimation { self.didCopyData = true }
    }
}

/// Opens the run's data as a table, showing the columns chosen for export.
struct RunTableButton: View {
    let data: RunData
    let columns: Set<Int>?

    @State private var isShowingDataTable: Bool = false

    var body: some View {
        GlassIconButton(systemImage: "tablecells", title: "Table", label: "Preview Data Table") {
            self.isShowingDataTable = true
        }
        .fullScreenCover(isPresented: $isShowingDataTable) {
            DataTableView(data: data, columns: columns)
        }
    }
}
