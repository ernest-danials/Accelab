//
//  AnalyzeStepView.swift
//  Accelab
//

import SwiftUI

/// A short pause between tracking and the results, in which the run's distance–time curve draws itself.
/// The numbers are ready at once; the pause is there so the result reads as worked out rather than abrupt.
struct AnalyzeStepView: View {
    let splits: [DistanceSplit]
    let onFinished: () -> Void

    @State private var progress: CGFloat = 0
    @State private var phaseIndex: Int = 0

    private static let duration: TimeInterval = 2.4
    private static let phases = ["Fitting the track…", "Converting pixels to metres…", "Building your data…"]

    var body: some View {
        VStack(spacing: 14) {
            curve
                .trim(from: 0, to: progress)
                .stroke(Method.camera.color, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .frame(width: 280, height: 110)
                .padding(18)
                .glassEffect(.regular, in: .rect(cornerRadius: 24))

            Text(Self.phases[phaseIndex])
                .customFont(.subheadline, weight: .medium)
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
        }
        .offset(y: 20)
        .task {
            // Cancelled automatically if the step changes first.
            withAnimation(.easeInOut(duration: Self.duration * 0.9)) { self.progress = 1 }

            for index in Self.phases.indices.dropFirst() {
                guard (try? await Task.sleep(for: .seconds(Self.duration / Double(Self.phases.count)))) != nil else { return }
                withAnimation { self.phaseIndex = index }
            }

            guard (try? await Task.sleep(for: .seconds(Self.duration / Double(Self.phases.count)))) != nil else { return }
            onFinished()
        }
    }

    /// Distance against time, scaled to fill the frame it is drawn in.
    private var curve: Path {
        Path { path in
            let size = CGSize(width: 280, height: 110)
            let maxTime = max(splits.last?.timeElapsed ?? 0, .leastNonzeroMagnitude)
            let maxDistance = max(splits.map(\.displacement).max() ?? 0, .leastNonzeroMagnitude)

            for (index, split) in splits.enumerated() {
                let point = CGPoint(x: size.width * split.timeElapsed / maxTime, y: size.height * (1 - max(split.displacement, 0) / maxDistance))
                if index == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
        }
    }
}
