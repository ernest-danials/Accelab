//
//  AnalyzeStepView.swift
//  Accelab
//

import SwiftUI

/// A short pause between tracking and the results, in which the run's curve draws itself: distance
/// against time for a cart on a track, or height against horizontal distance (the flight itself) for a
/// projectile.
/// The numbers are ready at once; the pause is there so the result reads as worked out rather than abrupt.
struct AnalyzeStepView: View {
    let data: RunData
    let onFinished: () -> Void

    @State private var progress: CGFloat = 0
    @State private var phaseIndex: Int = 0

    private static let duration: TimeInterval = 2.4
    private static let graphSize = CGSize(width: 240, height: 96)

    var body: some View {
        VStack(spacing: 14) {
            // Labelled as a graph: without the axes it is just a rising line.
            VStack(alignment: .leading, spacing: 6) {
                Text("Your run")
                    .customFont(.caption, weight: .bold)

                HStack(alignment: .center, spacing: 6) {
                    Text(verticalAxisLabel)
                        .customFont(.caption2, weight: .medium)
                        .foregroundStyle(.secondary)
                        .fixedSize()
                        .rotationEffect(.degrees(-90))
                        .frame(width: 14)

                    curve
                        .trim(from: 0, to: progress)
                        .stroke(Method.camera.color, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                        .frame(width: Self.graphSize.width, height: Self.graphSize.height)
                        .padding(.leading, 6)
                        .padding(.bottom, 6)
                        .overlay(alignment: .bottomLeading) {
                            // The two axes.
                            Path { path in
                                path.move(to: .zero)
                                path.addLine(to: CGPoint(x: 0, y: Self.graphSize.height + 6))
                                path.addLine(to: CGPoint(x: Self.graphSize.width + 6, y: Self.graphSize.height + 6))
                            }
                            .stroke(.secondary, lineWidth: 1)
                        }
                }

                Text(horizontalAxisLabel)
                    .customFont(.caption2, weight: .medium)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(16)
            .fixedSize()
            .glassEffect(.regular, in: .rect(cornerRadius: 24))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(graphDescription)

            Text(phases[phaseIndex])
                .customFont(.subheadline, weight: .medium)
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
        }
        .offset(y: 20)
        .task {
            // Cancelled automatically if the step changes first.
            withAnimation(.easeInOut(duration: Self.duration * 0.9)) { self.progress = 1 }

            for index in phases.indices.dropFirst() {
                guard (try? await Task.sleep(for: .seconds(Self.duration / Double(phases.count)))) != nil else { return }
                withAnimation { self.phaseIndex = index }
            }

            guard (try? await Task.sleep(for: .seconds(Self.duration / Double(phases.count)))) != nil else { return }
            onFinished()
        }
    }

    private var verticalAxisLabel: String {
        switch data {
        case .distance:
            return "Distance"
        case .position:
            return "Height"
        }
    }

    private var horizontalAxisLabel: String {
        switch data {
        case .distance:
            return "Time"
        case .position:
            return "Distance"
        }
    }

    private var graphDescription: String {
        switch data {
        case .distance:
            return "Graph of your run: distance against time"
        case .position:
            return "Graph of your run: height against horizontal distance"
        }
    }

    /// What the pause claims to be doing; the second and third are the same for both kinds of run.
    private var phases: [String] {
        switch data {
        case .distance:
            return ["Fitting the track…", "Converting pixels to metres…", "Building your data…"]
        case .position:
            return ["Setting the origin…", "Converting pixels to metres…", "Building your data…"]
        }
    }

    private var curve: Path {
        Path { path in
            path.addLines(curvePoints)
        }
    }

    /// The run's samples as points inside `graphSize`, with y measured downwards from the top as drawing needs.
    private var curvePoints: [CGPoint] {
        switch data {
        case .distance(let splits):
            return distancePoints(for: splits)
        case .position(let splits):
            return flightPoints(for: splits)
        }
    }

    /// Distance against time, scaled to fill the frame it is drawn in.
    private func distancePoints(for splits: [DistanceSplit]) -> [CGPoint] {
        let size = Self.graphSize
        let maxTime = max(splits.last?.timeElapsed ?? 0, .leastNonzeroMagnitude)
        let maxDistance = max(splits.map(\.displacement).max() ?? 0, .leastNonzeroMagnitude)

        return splits.map { split in
            CGPoint(x: size.width * split.timeElapsed / maxTime, y: size.height * (1 - max(split.displacement, 0) / maxDistance))
        }
    }

    /// Height against horizontal distance, fitted inside the frame with one scale on both axes so the path
    /// keeps its true shape. The lowest x sits on the left edge and the lowest y on the bottom edge. y is
    /// positive upwards in the data and can be negative when the ball lands below where it started, so it
    /// is measured from the lowest sample and flipped for drawing.
    private func flightPoints(for splits: [PositionSplit]) -> [CGPoint] {
        guard let first = splits.first else { return [] }

        let size = Self.graphSize
        let minX = splits.map(\.x).min() ?? first.x
        let maxX = splits.map(\.x).max() ?? first.x
        let minY = splits.map(\.y).min() ?? first.y
        let maxY = splits.map(\.y).max() ?? first.y
        let spanX = CGFloat(maxX - minX)
        let spanY = CGFloat(maxY - minY)

        // An axis with no range cannot limit the scale. With no range on either (one sample, or a ball that
        // never moved) there is nothing to scale, so everything sits in the bottom-left corner.
        let fittedScale = min(spanX > 0 ? size.width / spanX : .infinity, spanY > 0 ? size.height / spanY : .infinity)
        let scale = fittedScale.isFinite ? fittedScale : 0

        return splits.map { split in
            CGPoint(x: CGFloat(split.x - minX) * scale, y: size.height - CGFloat(split.y - minY) * scale)
        }
    }
}
