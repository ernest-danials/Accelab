//
//  RunSummaryView.swift
//  Accelab
//

import SwiftUI

/// The angle and the data of a run side by side, for a run just finished and for a saved one.
struct RunSummaryView: View {
    /// `nil` when the angle steps were skipped.
    let desiredAngle: Double?
    let capturedAngle: Double?
    let splits: [DistanceSplit]

    var body: some View {
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
    }
}
