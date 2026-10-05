//
//  RecordStepView.swift
//  Accelab
//

import PhotosUI
import SwiftUI

struct RecordStepView: View {
    let onBack: () -> Void
    /// Called with the clip's location in the temporary directory once it has been copied there.
    let onImported: (URL) -> Void

    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var isImporting: Bool = false
    @State private var didFailToImport: Bool = false

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                if isImporting {
                    ProgressView("Importing…")
                } else {
                    PhotosPicker(selection: $selectedItem, matching: .videos, preferredItemEncoding: .current) {
                        Label("Choose from Photos", systemImage: "photo.on.rectangle")
                            .customFont(.title3, weight: .medium)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 20)
                    }
                    .buttonStyle(.glassProminent)

                    // TODO: Record in the app instead, with focus, exposure and frame rate locked.
                    Text("Recording in Accelab is coming soon. For now, film the run with the Camera app and choose the video here.")
                        .customFont(.footnote, weight: .medium)
                        .multilineTextAlignment(.center)
                        .frame(width: 300)

                    if didFailToImport {
                        Text("That video couldn't be imported. Please try another one.")
                            .customFont(.footnote, weight: .medium)
                            .foregroundStyle(.red)
                    }
                }
            }
            .offset(y: 15)

            GlassButton(text: "Back", style: .secondary, isDisabled: isImporting, perform: onBack)
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
}
