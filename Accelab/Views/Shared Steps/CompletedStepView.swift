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
    /// Called once the user has agreed to leave the run and go home.
    let onExit: () -> Void

    @State private var isShowingConfirmationDialogToExit: Bool = false

    var body: some View {
        ZStack {
            RunSummaryView(desiredAngle: desiredAngle, capturedAngle: capturedAngle, splits: splits)
                .offset(y: 15)

            GlassEffectContainer {
                HStack {
                    RunExportControls(splits: splits, csvURL: csvURL, desmosURL: desmosURL, offersMedia: offersMedia, videoURL: videoURL, photoURL: photoURL, onRetryExport: onRetryExport)

                    GlassIconButton(systemImage: "checkmark", label: "Done") {
                        self.isShowingConfirmationDialogToExit = true
                    }
                    .confirmationDialog(exitMessage, isPresented: $isShowingConfirmationDialogToExit, titleVisibility: .visible) {
                        Button("Yes, go back", role: .destructive, action: onExit)
                    }
                }
                .alignView(to: .trailing)
                .alignViewVertically(to: .bottom)
                .padding()
            }
        }
        .onAppear {
            // Both methods end here, so this is where finishing a run is felt.
            Haptics.success()
        }
    }

    /// The run itself stays in the past runs; only the video goes with the screen.
    private var exitMessage: String {
        if videoURL != nil {
            "This will take you back to the home screen. Your data stays in Past Runs, but the video isn't kept. Are you sure?"
        } else {
            "This will take you back to the home screen. Your data stays in Past Runs. Are you sure?"
        }
    }
}
