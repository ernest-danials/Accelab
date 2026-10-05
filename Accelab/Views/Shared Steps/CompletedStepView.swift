//
//  CompletedStepView.swift
//  Accelab
//

import SwiftUI

struct CompletedStepView: View {
    /// `nil` when the angle steps were skipped.
    let desiredAngle: Double?
    let capturedAngle: Double?
    let splits: [DistanceSplit]
    let csvURL: URL?
    /// The data as a text file Desmos can import.
    let desmosURL: URL?
    /// `true` for the camera method, whose export is a menu of the data, the video and the photo.
    var offersMedia: Bool = false
    /// The recorded clip, when the run was filmed in the app. `nil` for the sensor method and imported clips.
    var videoURL: URL? = nil
    /// A photo of the last tracked frame with every point on it. `nil` for the sensor method, and
    /// until it has been drawn.
    var photoURL: URL? = nil
    let onRetryExport: () -> Void
    /// Called once the user has agreed to discard the run and go home.
    let onExit: () -> Void

    @State private var isShowingConfirmationDialogToExit: Bool = false
    @State private var isShowingDataTable: Bool = false
    @State private var didCopyData: Bool = false

    var body: some View {
        ZStack {
            HStack(spacing: 15) {
                VStack {
                    Image(systemName: "angle")
                        .customFont(.title3, weight: .bold)
                        .padding(.bottom, 2)

                    if let desiredAngle {
                        Text("Target Angle: \(desiredAngle, specifier: "%.2f")°")
                            .customFont(.title3, weight: .bold)

                        if let capturedAngle {
                            Text("Actual Angle: \(capturedAngle, specifier: "%.2f")°")
                                .customFont(.title3, weight: .bold)
                        } else {
                            Text("Actual Angle: Error")
                                .customFont(.title3, weight: .bold)
                        }

                        Text("Margin: \(abs(desiredAngle - (capturedAngle ?? 0)), specifier: "%.2f")°")
                            .customFont(.footnote, weight: .medium)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Angle Not Measured")
                            .customFont(.title3, weight: .bold)

                        Text("The angle step was skipped.")
                            .customFont(.footnote, weight: .medium)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()
                    .frame(height: 150)

                VStack {
                    Image(systemName: "tablecells")
                        .customFont(.title3, weight: .bold)
                        .padding(.bottom, 2)

                    if let lastSplit = splits.last {
                        Text("Time Elapsed: \(lastSplit.timeElapsed, specifier: "%.2f") s")
                            .customFont(.title3, weight: .bold)

                        Text("Distance Travelled: \(lastSplit.displacement, specifier: "%.2f") m")
                            .customFont(.title3, weight: .bold)
                    }

                    Text("\(splits.count) Splits")
                        .customFont(.footnote, weight: .medium)
                        .foregroundStyle(.secondary)
                }
            }
            .offset(y: 15)

            GlassEffectContainer {
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

                    GlassIconButton(systemImage: "checkmark", label: "Done") {
                        self.isShowingConfirmationDialogToExit = true
                    }
                    .confirmationDialog("This will reset all your data and take you back to the home screen. Are you sure?", isPresented: $isShowingConfirmationDialogToExit, titleVisibility: .visible) {
                        Button("Yes, reset and go back", role: .destructive, action: onExit)
                    }
                }
                .alignView(to: .trailing)
                .alignViewVertically(to: .bottom)
                .padding()
            }
        }
        .fullScreenCover(isPresented: $isShowingDataTable) {
            DataTableView(splits: splits)
        }
        .task(id: didCopyData) {
            // Shows "Copied" for a moment, then offers the copy again.
            guard didCopyData, (try? await Task.sleep(for: .seconds(1.5))) != nil else { return }
            withAnimation { self.didCopyData = false }
        }
        .onAppear {
            // Both methods end here, so this is where finishing a run is felt.
            Haptics.success()
        }
    }

    /// Puts the data on the clipboard as rows Desmos turns into a table when pasted.
    private func copyDataForDesmos() {
        UIPasteboard.general.string = CSVExporter.makeDesmosText(from: splits)
        Haptics.success()
        withAnimation { self.didCopyData = true }
    }
}
