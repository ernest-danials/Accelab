//
//  RunSummaryView.swift
//  Accelab
//

import SwiftUI

/// The headline numbers of a run in two columns, for a run just finished and for a saved one: the angle
/// beside the data for a run along a track, and where a projectile ended up beside its flight.
struct RunSummaryView: View {
    /// `nil` when the angle steps were skipped. Not shown for a projectile run, which has no angle.
    let desiredAngle: Double?
    let capturedAngle: Double?
    let data: RunData

    var body: some View {
        HStack(spacing: 15) {
            switch data {
            case .distance(let splits):
                angleColumn

                Divider()
                    .frame(height: 150)

                distanceColumn(for: splits)
            case .position(let splits):
                positionColumn(for: splits)

                Divider()
                    .frame(height: 150)

                flightColumn(for: splits)
            }
        }
    }

    // MARK: - A run along a track

    private var angleColumn: some View {
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
    }

    private func distanceColumn(for splits: [DistanceSplit]) -> some View {
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

    // MARK: - A projectile

    /// Where the projectile was on the last tracked frame.
    private func positionColumn(for splits: [PositionSplit]) -> some View {
        VStack {
            Image(systemName: Method.projectile.imageName)
                .customFont(.title3, weight: .bold)
                .padding(.bottom, 2)

            if let lastSplit = splits.last {
                Text("Horizontal Distance: \(Self.lengthText(for: lastSplit.x)) m")
                    .customFont(.title3, weight: .bold)

                Text("Final Height: \(Self.lengthText(for: lastSplit.y)) m")
                    .customFont(.title3, weight: .bold)
            }

            Text("Measured from the starting point.")
                .customFont(.footnote, weight: .medium)
                .foregroundStyle(.secondary)
        }
    }

    private func flightColumn(for splits: [PositionSplit]) -> some View {
        VStack {
            Image(systemName: "tablecells")
                .customFont(.title3, weight: .bold)
                .padding(.bottom, 2)

            if let lastSplit = splits.last {
                Text("Time Elapsed: \(lastSplit.timeElapsed, specifier: "%.2f") s")
                    .customFont(.title3, weight: .bold)

                // Never below zero: the projectile starts at the origin.
                Text("Peak Height: \(Self.lengthText(for: splits.map(\.y).max() ?? 0)) m")
                    .customFont(.title3, weight: .bold)
            }

            Text("\(splits.count) Points")
                .customFont(.footnote, weight: .medium)
                .foregroundStyle(.secondary)
        }
    }

    /// A length to the centimetre, written for the user's region like the numbers beside it. A value that
    /// rounds to nothing loses its minus sign.
    private static func lengthText(for meters: Double) -> String {
        let rounded = (meters * 100).rounded() / 100
        return String(format: "%.2f", locale: .current, rounded == 0 ? 0 : rounded)
    }
}

#Preview("Projectile", traits: .landscapeLeft) {
    RunSummaryView(desiredAngle: nil, capturedAngle: nil, data: .position((0..<40).map { PositionSplit(timeElapsed: Double($0) / 60, x: 2.5 * Double($0) / 60, y: 3 * Double($0) / 60 - 4.905 * pow(Double($0) / 60, 2)) }))
}
