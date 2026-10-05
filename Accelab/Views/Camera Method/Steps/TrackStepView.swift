//
//  TrackStepView.swift
//  Accelab
//

import SwiftUI

struct TrackStepView: View {
    let scrubber: VideoScrubber
    @Binding var points: [TrackedPoint]
    let onBack: () -> Void
    let onFinish: () -> Void

    /// How far the clip moves on after each mark.
    private static let markInterval: TimeInterval = 0.1
    /// A distance–time curve needs at least this many samples to be worth exporting.
    private static let minimumPointCount = 3

    var body: some View {
        // Read here rather than inside the overlay, so the highlight follows the scrubber.
        let currentFrameIndex = scrubber.currentFrameIndex

        ZStack {
            VideoFrameViewer(scrubber: scrubber, onTap: mark) { mapping in
                ForEach(points) { point in
                    let isCurrent = point.frameIndex == currentFrameIndex

                    Circle()
                        .fill(isCurrent ? .yellow : .white.opacity(0.7))
                        .stroke(.black.opacity(0.5), lineWidth: 1)
                        .frame(width: isCurrent ? 12 : 7, height: isCurrent ? 12 : 7)
                        .position(mapping.viewPoint(for: point.position))
                }
                .allowsHitTesting(false)
            }
            .containerRelativeFrame(.horizontal) { width, _ in width * 0.6 }
            .padding(.top)
            .padding(.bottom, 70)
            .alignView(to: .trailing)

            VStack(alignment: .leading, spacing: 8) {
                Text("^[\(points.count) point](inflect: true) marked")
                    .customFont(.title3, weight: .bold)
                    .contentTransition(.numericText(value: Double(points.count)))

                Text("Tap the same spot on the cart each time. The video moves on after every tap.")
                    .customFont(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    GlassButton(text: "Undo", style: .secondary, textFont: .subheadline, isDisabled: points.isEmpty, perform: undo)

                    GlassButton(text: "Clear", style: .secondary, textFont: .subheadline, isDisabled: points.isEmpty, perform: clear)
                }
            }
            .frame(width: 260, alignment: .leading)
            .padding(.horizontal, 30)
            .alignView(to: .leading)
            .offset(y: 30)

            HStack {
                GlassButton(text: "Back", style: .secondary, perform: onBack)

                GlassButton(text: "Finish", isDisabled: points.count < Self.minimumPointCount, perform: onFinish)
            }
            .alignView(to: .trailing)
            .alignViewVertically(to: .bottom)
            .padding()
        }
    }

    /// Marks the cart on the current frame, replacing an earlier mark on it, and moves on.
    private func mark(at position: CGPoint) {
        let frameIndex = scrubber.currentFrameIndex

        withAnimation {
            self.points.removeAll { $0.frameIndex == frameIndex }
            self.points.append(TrackedPoint(frameIndex: frameIndex, position: position))
            self.points.sort { $0.frameIndex < $1.frameIndex }
        }

        scrubber.step(bySeconds: Self.markInterval)
    }

    /// Removes every mark and returns to where marking began.
    private func clear() {
        guard let first = points.first else { return }

        withAnimation { self.points = [] }
        scrubber.seek(toFrame: first.frameIndex)
    }

    /// Removes the latest mark and returns to its frame so it can be placed again.
    private func undo() {
        guard let last = points.last else { return }

        withAnimation { _ = self.points.removeLast() }
        scrubber.seek(toFrame: last.frameIndex)
    }
}
