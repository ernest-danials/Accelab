//
//  RecordStepView.swift
//  Accelab
//

import PhotosUI
import SwiftUI

struct RecordStepView: View {
    let captureManager: CameraCaptureManager
    let onBack: () -> Void
    let onRecord: () -> Void
    let onStop: () -> Void
    /// Called with the clip's location in the temporary directory once it has been copied there.
    let onImported: (URL) -> Void

    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var isImporting: Bool = false
    @State private var didFailToImport: Bool = false

    var body: some View {
        ZStack {
            preview
                .containerRelativeFrame(.horizontal) { width, _ in width * 0.6 }
                .padding(.top)
                .padding(.bottom, 70)
                .alignView(to: .trailing)

            VStack(alignment: .leading, spacing: 8) {
                if isImporting {
                    ProgressView("Importing…")
                } else {
                    Text("Already filmed the run?")
                        .customFont(.caption)
                        .foregroundStyle(.secondary)

                    PhotosPicker(selection: $selectedItem, matching: .videos, preferredItemEncoding: .current) {
                        Label("Choose from Photos", systemImage: "photo.on.rectangle")
                            .customFont(.subheadline, weight: .medium)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 12)
                    }
                    .buttonStyle(.glass)
                    .disabled(isRecording)

                    if didFailToImport {
                        Text("That video couldn't be imported. Please try another one.")
                            .customFont(.caption, weight: .medium)
                            .foregroundStyle(.red)
                    }
                }
            }
            .frame(width: 260, alignment: .leading)
            .padding(.horizontal, 30)
            .alignView(to: .leading)
            .offset(y: 30)

            GlassButton(text: "Back", style: .secondary, isDisabled: isImporting || isRecording, perform: onBack)
                .alignView(to: .trailing)
                .alignViewVertically(to: .bottom)
                .padding()
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }

            Task {
                self.isImporting = true
                self.didFailToImport = false

                let video = try? await newItem.loadTransferable(type: ImportedVideo.self)

                self.isImporting = false
                self.selectedItem = nil

                if let video {
                    onImported(video.url)
                } else {
                    self.didFailToImport = true
                }
            }
        }
    }

    private var isRecording: Bool {
        captureManager.state == .recording || captureManager.state == .finishing
    }

    @ViewBuilder
    private var preview: some View {
        ZStack {
            Color.black

            switch captureManager.state {
            case .ready, .recording, .finishing:
                CameraPreviewView(captureManager: captureManager)

                recordButton
                    .alignView(to: .trailing)
                    .padding()

                if let recordingStartDate = captureManager.recordingStartDate {
                    Text(recordingStartDate, style: .timer)
                        .customFont(.subheadline, weight: .bold)
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(.red, in: .capsule)
                        .alignViewVertically(to: .top)
                        .padding()
                }
            case .unauthorized:
                unavailableMessage("Accelab needs camera access to record the run.", systemImage: "video.slash") {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.glass)
                }
            case .unavailable:
                unavailableMessage("The camera isn't available. Choose a video from Photos instead.", systemImage: "video.slash") { EmptyView() }
            case .idle, .starting:
                ProgressView()
                    .tint(.white)
            }
        }
        .clipShape(.rect(cornerRadius: 16))
    }

    private var recordButton: some View {
        Button {
            if captureManager.state == .recording {
                onStop()
            } else {
                onRecord()
            }
        } label: {
            ZStack {
                Circle()
                    .stroke(.white, lineWidth: 4)
                    .frame(width: 62, height: 62)

                RoundedRectangle(cornerRadius: captureManager.state == .recording ? 6 : 25)
                    .fill(.red)
                    .frame(width: captureManager.state == .recording ? 26 : 50, height: captureManager.state == .recording ? 26 : 50)
            }
            .animation(.smooth(duration: 0.2), value: captureManager.state == .recording)
        }
        .buttonStyle(.plain)
        .disabled(captureManager.state == .finishing)
        .accessibilityLabel(captureManager.state == .recording ? "Stop Recording" : "Record")
    }

    private func unavailableMessage<Action: View>(_ text: String, systemImage: String, @ViewBuilder action: () -> Action) -> some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .customFont(.title, weight: .medium)

            Text(text)
                .customFont(.subheadline, weight: .medium)
                .multilineTextAlignment(.center)

            action()
        }
        .foregroundStyle(.white)
        .padding()
    }
}
