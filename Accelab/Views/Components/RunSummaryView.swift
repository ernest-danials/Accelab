//
//  RunSummaryView.swift
//  Accelab
//

import SwiftUI

/// The headline numbers of a run in two columns, for a run just finished and for a saved one: the angle
/// beside the data for a run along a track, where a projectile ended up beside its flight, how fast a
/// turntable went round beside how long it was measured, and the circle a marker traced beside its points.
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
            case .rotation(let splits):
                spinColumn(for: splits)

                Divider()
                    .frame(height: 150)

                samplesColumn(for: splits)
            case .circle(let splits):
                circleColumn(for: splits)

                Divider()
                    .frame(height: 150)

                pointsColumn(for: splits)
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
            Image(systemName: CameraExperiment.projectile.imageName)
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

    // MARK: - A turntable

    private func spinColumn(for splits: [RotationSplit]) -> some View {
        VStack {
            Image(systemName: SensorExperiment.circularMotion.imageName)
                .customFont(.title3, weight: .bold)
                .padding(.bottom, 2)

            if !splits.isEmpty {
                Text("Fastest Spin: \(splits.map(\.angularVelocity).max() ?? 0, specifier: "%.2f") rad/s")
                    .customFont(.title3, weight: .bold)

                Text("Peak Acceleration: \(splits.map(\.centripetalAcceleration).max() ?? 0, specifier: "%.2f") m/s²")
                    .customFont(.title3, weight: .bold)
            }

            Text("Read from the gyroscope and accelerometer.")
                .customFont(.footnote, weight: .medium)
                .foregroundStyle(.secondary)
        }
    }

    private func samplesColumn(for splits: [RotationSplit]) -> some View {
        VStack {
            Image(systemName: "tablecells")
                .customFont(.title3, weight: .bold)
                .padding(.bottom, 2)

            if let lastSplit = splits.last {
                Text("Time Elapsed: \(lastSplit.timeElapsed, specifier: "%.2f") s")
                    .customFont(.title3, weight: .bold)
            }

            Text("\(splits.count) Samples")
                .customFont(.footnote, weight: .medium)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - A marker going round

    /// The circle fitted through the points: its radius, and how many times round the marker went.
    private func circleColumn(for splits: [CircleSplit]) -> some View {
        VStack {
            Image(systemName: CameraExperiment.circularMotion.imageName)
                .customFont(.title3, weight: .bold)
                .padding(.bottom, 2)

            if !splits.isEmpty {
                Text("Radius: \(Self.lengthText(for: splits.fittedRadius)) m")
                    .customFont(.title3, weight: .bold)

                Text("Turns: \(splits.turns, specifier: "%.2f")")
                    .customFont(.title3, weight: .bold)
            }

            Text("From the circle fitted through the points.")
                .customFont(.footnote, weight: .medium)
                .foregroundStyle(.secondary)
        }
    }

    private func pointsColumn(for splits: [CircleSplit]) -> some View {
        VStack {
            Image(systemName: "tablecells")
                .customFont(.title3, weight: .bold)
                .padding(.bottom, 2)

            if let lastSplit = splits.last {
                Text("Time Elapsed: \(lastSplit.timeElapsed, specifier: "%.2f") s")
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

#Preview("Circle", traits: .landscapeLeft) {
    RunSummaryView(desiredAngle: nil, capturedAngle: nil, data: .circle((0..<90).map { index in
        let angle = 2 * Double.pi * Double(index) / 30
        return CircleSplit(timeElapsed: Double(index) / 15, x: 0.2 * cos(angle), y: 0.2 * sin(angle), angle: angle, radius: 0.2)
    }))
}

#Preview("Circular Motion", traits: .landscapeLeft) {
    RunSummaryView(desiredAngle: nil, capturedAngle: nil, data: .rotation((0..<40).map { index in
        let angularVelocity = index < 20 ? 0.4 * Double(index) : 0.4 * Double(40 - index)
        return RotationSplit(timeElapsed: Double(index) / 4, angularVelocity: angularVelocity, centripetalAcceleration: angularVelocity * angularVelocity * 0.15, tangentialAcceleration: 0.05)
    }))
}
