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
    @State private var isChromeHidden: Bool = false

    var body: some View {
        ZStack {
            preview
                .onTapGesture {
                    // Only while there is a picture to look at; otherwise the controls are all there is.
                    guard isCameraRunning else { return }
                    withAnimation(.smooth) { self.isChromeHidden.toggle() }
                }

            VideoStepLayout(step: .record, instruction: isRecording ? "Release the cart, then stop once it reaches the end of the track." : "Press the red button to start recording, or choose a video you already filmed.", isChromeHidden: isChromeHidden) {
                VStack(alignment: .trailing, spacing: 8) {
                    if isImporting {
                        GlassStatusLabel {
                            HStack(spacing: 8) {
                                ProgressView()

                                Text("Importing…")
                            }
                        }
                    } else {
                        PhotosPicker(selection: $selectedItem, matching: .videos, preferredItemEncoding: .current) {
                            GlassIconLabel(systemImage: "photo.on.rectangle")
                        }
                        .buttonStyle(.plain)
                        .disabled(isRecording)
                        .opacity(isRecording ? 0.5 : 1)
                        .accessibilityLabel("Choose from Photos")
                    }

                    if didFailToImport {
                        GlassStatusLabel {
                            Label("That video couldn't be imported", systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                }
            } bottom: {
                GlassIconButton(systemImage: "chevron.backward", label: "Back", isDisabled: isImporting || isRecording, perform: onBack)
                    .hiddenWithChrome(isChromeHidden)

                Spacer(minLength: 0)

                // The timer and the record button stay when the rest is hidden.
                if let recordingStartDate = captureManager.recordingStartDate {
                    GlassStatusLabel {
                        Label {
                            Text(recordingStartDate, style: .timer)
                        } icon: {
                            Image(systemName: "circle.fill")
                                .foregroundStyle(.red)
                        }
                    }
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
        .onChange(of: isCameraRunning) { _, isRunning in
            // Without a picture the controls must be reachable.
            if !isRunning { self.isChromeHidden = false }
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
                CameraPreviewView(captureManager: captureManager)
            case .unauthorized:
                unavailableMessage("Accelab needs camera access to record the run.") {
                    GlassIconButton(systemImage: "gear", title: "Open Settings", label: "Open Settings") {
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
        .contentShape(.rect)
        .ignoresSafeArea()
        .environment(\.colorScheme, .dark)
    }

    private var recordButton: some View {
        Button {
            Haptics.heavyTap()
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
