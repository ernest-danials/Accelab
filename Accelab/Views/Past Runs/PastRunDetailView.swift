//
//  PastRunDetailView.swift
//  Accelab
//

import SwiftUI
import SwiftData

/// A saved run with what the completed step offers for a run just finished, plus renaming and deleting it.
struct PastRunDetailView: View {
    let run: SavedRun

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var splits: [DistanceSplit] = []
    @State private var csvURL: URL? = nil
    @State private var desmosURL: URL? = nil
    @State private var photo: UIImage? = nil
    @State private var photoURL: URL? = nil

    @State private var runBeingRenamed: SavedRun? = nil
    @State private var isShowingPhoto: Bool = false
    @State private var isShowingConfirmationDialogToDelete: Bool = false

    var body: some View {
        ZStack {
            RunSummaryView(desiredAngle: run.desiredAngle, capturedAngle: run.capturedAngle, splits: splits)
                .padding(.horizontal)
                .padding(.bottom, 40)

            GlassEffectContainer {
                HStack {
                    GlassIconButton(systemImage: "trash", label: "Delete Run") {
                        self.isShowingConfirmationDialogToDelete = true
                    }
                    .foregroundStyle(.red)
                    .confirmationDialog("This will delete this run. Are you sure?", isPresented: $isShowingConfirmationDialogToDelete, titleVisibility: .visible) {
                        Button("Yes, delete", role: .destructive, action: deleteRun)
                    }

                    Spacer()

                    RunExportControls(splits: splits, csvURL: csvURL, desmosURL: desmosURL, offersMedia: run.method == .camera, photoURL: photoURL, onRetryExport: exportFiles)
                }
                .alignViewVertically(to: .bottom)
                .padding()
            }
        }
        .navigationTitle(run.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if photo != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Photo with Points", systemImage: "photo") { self.isShowingPhoto = true }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Rename", systemImage: "pencil") { self.runBeingRenamed = run }
            }
        }
        .renameRunCover(for: $runBeingRenamed)
        .fullScreenCover(isPresented: $isShowingPhoto) {
            if let photo {
                RunPhotoView(photo: photo, photoURL: photoURL)
            }
        }
        .task {
            self.splits = run.makeSplits()
            self.photo = run.photo.flatMap(UIImage.init(data:))
            exportFiles()
        }
    }

    /// Writes the run's files where they can be shared from. They are removed when the past runs are closed.
    private func exportFiles() {
        self.csvURL = CSVExporter.writeTempFile(for: splits)
        self.desmosURL = CSVExporter.writeDesmosTempFile(for: splits)

        RunMediaExporter.removeTempFiles()
        self.photoURL = run.photo.flatMap(RunMediaExporter.writePhotoFile(from:))
    }

    private func deleteRun() {
        dismiss()
        modelContext.delete(run)
    }
}

/// The photo of a camera run's tracked points, as large as the screen allows.
private struct RunPhotoView: View {
    let photo: UIImage
    /// The photo as a file to share. `nil` if writing it failed.
    let photoURL: URL?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Image(uiImage: photo)
                .resizable()
                .scaledToFit()
                .navigationTitle("Photo with Points")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if let photoURL {
                        ToolbarItem(placement: .topBarLeading) {
                            ShareLink(item: photoURL, preview: SharePreview("Accelab Photo", icon: Image(systemName: "photo")))
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .close) {
                            dismiss()
                        }
                    }
                }
        }
    }
}
