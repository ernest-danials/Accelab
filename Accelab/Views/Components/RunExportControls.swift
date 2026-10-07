//
//  RunExportControls.swift
//  Accelab
//

import SwiftUI

/// The Table, Desmos and Export controls of a run, for a run just finished and for a saved one.
/// Place it in a row inside a `GlassEffectContainer`.
struct RunExportControls: View {
    let data: RunData
    let csvURL: URL?
    /// The data as a text file Desmos can import.
    let desmosURL: URL?
    /// `true` for the methods that film the run, whose export is a menu of the data, the video and the photo.
    var offersMedia: Bool = false
    /// The recorded clip, when the run was filmed in the app. `nil` for the sensor method, imported clips and saved runs.
    var videoURL: URL? = nil
    /// A photo of the last tracked frame with every point on it. `nil` for the sensor method, and
    /// until it has been drawn.
    var photoURL: URL? = nil
    let onRetryExport: () -> Void

    @State private var isShowingDataTable: Bool = false
    @State private var didCopyData: Bool = false

    var body: some View {
        HStack {
            GlassIconButton(systemImage: "tablecells", title: "Table", label: "Preview Data Table") {
                self.isShowingDataTable = true
            }

            Menu {
                Button("Copy Data", systemImage: "doc.on.doc", action: copyDataForDesmos)

                if let desmosURL {
                    ShareLink(item: desmosURL, preview: SharePreview("Accelab Data for Desmos", icon: Image(systemName: "doc.plaintext"))) {
                        Label("Export as Text File", systemImage: "doc.plaintext")
                    }
                }
            } label: {
                // One label whose content changes, so "Copied" animates in rather than replacing the button.
                GlassIconLabel(systemImage: didCopyData ? "checkmark" : "x.squareroot", title: didCopyData ? "Copied" : "Desmos")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Desmos")

            if let url = csvURL, offersMedia {
                // More than the data to share, so the choices go in a menu.
                Menu {
                    ShareLink(item: url, preview: SharePreview("Accelab Data", icon: Image(systemName: "tablecells"))) {
                        Label("Data (CSV)", systemImage: "tablecells")
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
                } label: {
                    GlassIconLabel(systemImage: "square.and.arrow.up", title: "Export", style: .prominent)
                }
                .buttonStyle(.plain)
            } else if let url = csvURL {
                ShareLink(item: url, preview: SharePreview("Accelab Data", icon: Image(systemName: "tablecells"))) {
                    GlassIconLabel(systemImage: "square.and.arrow.up", title: "Export CSV", style: .prominent)
                }
                .buttonStyle(.plain)
            } else {
                // Only reachable if writing the temp file failed.
                GlassIconButton(systemImage: "arrow.clockwise", title: "Retry Export", label: "Retry Export", style: .prominent, perform: onRetryExport)
            }
        }
        .fullScreenCover(isPresented: $isShowingDataTable) {
            DataTableView(data: data)
        }
        .task(id: didCopyData) {
            // Shows "Copied" for a moment, then offers the copy again.
            guard didCopyData, (try? await Task.sleep(for: .seconds(1.5))) != nil else { return }
            withAnimation { self.didCopyData = false }
        }
    }

    /// Puts the data on the clipboard as rows Desmos turns into a table when pasted.
    private func copyDataForDesmos() {
        UIPasteboard.general.string = CSVExporter.makeDesmosText(from: data)
        Haptics.success()
        withAnimation { self.didCopyData = true }
    }
}
