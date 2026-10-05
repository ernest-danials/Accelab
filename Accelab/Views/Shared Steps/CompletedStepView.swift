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
    let onRetryExport: () -> Void
    /// Called once the user has agreed to discard the run and go home.
    let onExit: () -> Void

    @State private var isShowingConfirmationDialogToExit: Bool = false

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
                    if let url = csvURL {
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
        .onAppear {
            // Both methods end here, so this is where finishing a run is felt.
            Haptics.success()
        }
    }
}
