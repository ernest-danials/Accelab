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

            VideoStepLayout(step: .record) {
                VStack(alignment: .trailing, spacing: 8) {
                    if isImporting {
                        HStack(spacing: 8) {
                            ProgressView()

                            Text("Importing…")
                                .customFont(.subheadline, weight: .medium)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .glassEffect(.regular, in: .capsule)
                    } else {
                        PhotosPicker(selection: $selectedItem, matching: .videos, preferredItemEncoding: .current) {
                            Label("Choose from Photos", systemImage: "photo.on.rectangle")
                                .customFont(.subheadline, weight: .medium)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 8)
                        }
                        .buttonStyle(.glass)
                        .disabled(isRecording)
                    }

                    if didFailToImport {
                        Label("That video couldn't be imported.", systemImage: "exclamationmark.triangle.fill")
                            .customFont(.caption, weight: .medium)
                            .foregroundStyle(.red)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .glassEffect(.regular, in: .capsule)
                    }
                }
            } bottom: {
                GlassButton(text: "Back", style: .secondary, isDisabled: isImporting || isRecording, perform: onBack)

                Spacer(minLength: 0)

                if let recordingStartDate = captureManager.recordingStartDate {
                    Label {
                        Text(recordingStartDate, style: .timer)
                            .monospacedDigit()
                    } icon: {
                        Image(systemName: "circle.fill")
                            .foregroundStyle(.red)
                    }
                    .customFont(.subheadline, weight: .bold)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                    .glassEffect(.regular, in: .capsule)
                }
            }

            if isCameraRunning {
                recordButton
                    .alignView(to: .trailing)
                    .padding()
            }
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

    private var isCameraRunning: Bool {
        [.ready, .recording, .finishing].contains(captureManager.state)
    }

    /// The camera's picture filling the screen, or the reason there isn't one.
    @ViewBuilder
    private var preview: some View {
        ZStack {
            Color.black

            switch captureManager.state {
            case .ready, .recording, .finishing:
                // Fitted rather than filled, so what is on screen is exactly what is recorded.
                CameraPreviewView(captureManager: captureManager)
                    .aspectRatio(16.0 / 9.0, contentMode: .fit)
                    .clipShape(.rect(cornerRadius: 24))
            case .unauthorized:
                unavailableMessage("Accelab needs camera access to record the run.") {
                    GlassButton(text: "Open Settings", style: .secondary, textFont: .subheadline) {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            case .unavailable:
                unavailableMessage("The camera isn't available. Choose a video from Photos instead.") { EmptyView() }
            case .idle, .starting:
                ProgressView()
                    .tint(.white)
            }
        }
        .ignoresSafeArea()
    }

    private var recordButton: some View {
        Button {
            if captureManager.state == .recording {
                onStop()
            } else {
                onRecord()
            }
        } label: {
            RoundedRectangle(cornerRadius: captureManager.state == .recording ? 7 : 26)
                .fill(.red)
                .frame(width: captureManager.state == .recording ? 26 : 52, height: captureManager.state == .recording ? 26 : 52)
                .frame(width: 68, height: 68)
                .animation(.smooth(duration: 0.2), value: captureManager.state == .recording)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
        .disabled(captureManager.state == .finishing)
        .accessibilityLabel(captureManager.state == .recording ? "Stop Recording" : "Record")
    }

    private func unavailableMessage<Action: View>(_ text: String, @ViewBuilder action: () -> Action) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "video.slash")
                .customFont(.title, weight: .medium)

            Text(text)
                .customFont(.subheadline, weight: .medium)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)

            action()
        }
        .foregroundStyle(.white)
        .padding()
    }
}
