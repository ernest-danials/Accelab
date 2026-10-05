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

    @State private var mode: Mode = .marking
    /// The box drawn around the cart for automatic tracking, in pixels of the frame as it is shown.
    @State private var box: CGRect? = nil
    @State private var trackingTask: Task<Void, Never>? = nil
    @State private var didFailToTrack: Bool = false

    /// How far the clip moves on after each manual mark.
    private static let markInterval: TimeInterval = 0.1
    /// A distance–time curve needs at least this many samples to be worth exporting.
    private static let minimumPointCount = 3
    /// A smaller box gives the tracker too little to hold on to.
    private static let minimumBoxSide: CGFloat = 20

    private enum Mode {
        case marking, drawingBox, tracking
    }

    var body: some View {
        // Read here rather than inside the overlay, so the highlight follows the scrubber.
        let currentFrameIndex = scrubber.currentFrameIndex
        let onTap: ((CGPoint) -> Void)? = mode == .marking ? { mark(at: $0) } : nil

        ZStack {
            VideoFrameViewer(scrubber: scrubber, onTap: onTap) { mapping in
                ForEach(points) { point in
                    let isCurrent = point.frameIndex == currentFrameIndex

                    Circle()
                        .fill(color(for: point, isCurrent: isCurrent))
                        .stroke(.black.opacity(0.5), lineWidth: 1)
                        .frame(width: isCurrent ? 12 : 6, height: isCurrent ? 12 : 6)
                        .position(mapping.viewPoint(for: point.position))
                }
                .allowsHitTesting(false)

                if mode == .drawingBox {
                    boxDrawingLayer(mapping: mapping)
                }
            }
            .containerRelativeFrame(.horizontal) { width, _ in width * 0.6 }
            .padding(.top)
            .padding(.bottom, 70)
            .alignView(to: .trailing)

            VStack(alignment: .leading, spacing: 8) {
                switch mode {
                case .marking:
                    markingControls
                case .drawingBox:
                    boxControls
                case .tracking:
                    trackingControls
                }
            }
            .frame(width: 270, alignment: .leading)
            .padding(.horizontal, 30)
            .alignView(to: .leading)
            .offset(y: 25)

            if mode == .marking {
                editControls
                    .alignView(to: .leading)
                    .alignViewVertically(to: .bottom)
                    .padding()
            }

            HStack {
                GlassButton(text: "Back", style: .secondary, isDisabled: mode == .tracking, perform: onBack)

                GlassButton(text: "Finish", isDisabled: mode != .marking || points.count < Self.minimumPointCount, perform: onFinish)
            }
            .alignView(to: .trailing)
            .alignViewVertically(to: .bottom)
            .padding()
        }
        .onDisappear {
            trackingTask?.cancel()
        }
    }

    // MARK: - Controls

    @ViewBuilder
    private var markingControls: some View {
        Text("^[\(points.count) point](inflect: true) marked")
            .customFont(.title3, weight: .bold)
            .contentTransition(.numericText(value: Double(points.count)))

        if didFailToTrack {
            Text("Automatic tracking didn't work on this video. Tap the cart to mark it by hand.")
                .customFont(.caption, weight: .medium)
                .foregroundStyle(.red)
        } else if uncertainPointCount > 0 {
            Text("^[\(uncertainPointCount) point](inflect: true) in orange may be off. Go to its frame and tap the cart to correct it.")
                .customFont(.caption, weight: .medium)
                .foregroundStyle(.orange)
        } else {
            Text("Start at the frame where the cart is released. Tap the same spot on the cart on each frame, or track it automatically.")
                .customFont(.caption)
                .foregroundStyle(.secondary)
        }

        GlassButton(text: "Track Automatically", textFont: .subheadline) {
            self.didFailToTrack = false
            withAnimation { self.mode = .drawingBox }
        }
    }

    private var editControls: some View {
        HStack {
            GlassButton(text: "Undo", style: .secondary, textFont: .subheadline, isDisabled: points.isEmpty, perform: undo)

            GlassButton(text: "Clear", style: .secondary, textFont: .subheadline, isDisabled: points.isEmpty, perform: clear)

            Menu {
                Button("Remove Points Before This Frame") { trim(keeping: { $0 >= scrubber.currentFrameIndex }) }
                Button("Remove Points After This Frame") { trim(keeping: { $0 <= scrubber.currentFrameIndex }) }
            } label: {
                Text("Trim")
                    .customFont(.subheadline, weight: .medium)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 20)
            }
            .buttonStyle(.glass)
            .disabled(points.isEmpty)
        }
    }

    @ViewBuilder
    private var boxControls: some View {
        Text("Draw a Box")
            .customFont(.title3, weight: .bold)

        Text("Drag a box tightly around the cart on this frame. Accelab follows it from here to the end of the video.")
            .customFont(.caption)
            .foregroundStyle(.secondary)

        HStack {
            GlassButton(text: "Cancel", style: .secondary, textFont: .subheadline) {
                self.box = nil
                withAnimation { self.mode = .marking }
            }

            GlassButton(text: "Start", textFont: .subheadline, isDisabled: box == nil, perform: startTracking)
        }
    }

    @ViewBuilder
    private var trackingControls: some View {
        HStack {
            ProgressView()

            Text("Tracking…")
                .customFont(.title3, weight: .bold)
        }

        Text("^[\(points.count) point](inflect: true) so far")
            .customFont(.caption)
            .foregroundStyle(.secondary)
            .contentTransition(.numericText(value: Double(points.count)))

        GlassButton(text: "Stop", style: .secondary, textFont: .subheadline) {
            trackingTask?.cancel()
        }
    }

    /// Captures a drag over the frame as the box, and draws it.
    private func boxDrawingLayer(mapping: VideoViewMapping) -> some View {
        ZStack {
            Color.clear
                .contentShape(.rect)
                .gesture(
                    DragGesture(minimumDistance: 2, coordinateSpace: VideoViewMapping.coordinateSpace)
                        .onChanged { value in
                            let start = mapping.clamped(mapping.videoPoint(for: value.startLocation))
                            let end = mapping.clamped(mapping.videoPoint(for: value.location))
                            self.box = CGRect(x: min(start.x, end.x), y: min(start.y, end.y), width: abs(end.x - start.x), height: abs(end.y - start.y))
                        }
                        .onEnded { _ in
                            if let box, min(box.width, box.height) < Self.minimumBoxSide {
                                self.box = nil
                            }
                        }
                )

            if let box {
                let topLeft = mapping.viewPoint(for: box.origin)
                let bottomRight = mapping.viewPoint(for: CGPoint(x: box.maxX, y: box.maxY))

                Rectangle()
                    .stroke(.yellow, lineWidth: 2)
                    .frame(width: bottomRight.x - topLeft.x, height: bottomRight.y - topLeft.y)
                    .position(x: (topLeft.x + bottomRight.x) / 2, y: (topLeft.y + bottomRight.y) / 2)
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Actions

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

    /// Follows the boxed cart from the current frame on, replacing any points already there.
    private func startTracking() {
        guard let box, let frames = scrubber.frames else { return }

        let startFrame = scrubber.currentFrameIndex
        self.points.removeAll { $0.frameIndex >= startFrame }
        self.box = nil
        withAnimation { self.mode = .tracking }

        self.trackingTask = Task {
            var trackedCount = 0

            do {
                for try await point in VideoTracker.track(url: scrubber.url, frames: frames, startFrame: startFrame, box: box) {
                    self.points.append(point)
                    trackedCount += 1

                    // Follow along, but not on every frame: seeking is slower than tracking.
                    if trackedCount % 4 == 0 {
                        scrubber.seek(toFrame: point.frameIndex)
                    }
                }
            } catch {
                // Whatever was tracked before the failure is kept.
            }

            // The first point is the drawn box itself, so one point means nothing was followed.
            self.didFailToTrack = trackedCount < 2 && !Task.isCancelled
            if let last = points.last {
                scrubber.seek(toFrame: last.frameIndex)
            }
            withAnimation { self.mode = .marking }
        }
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

    private func trim(keeping shouldKeep: (Int) -> Bool) {
        withAnimation {
            self.points.removeAll { !shouldKeep($0.frameIndex) }
        }
    }

    private func color(for point: TrackedPoint, isCurrent: Bool) -> Color {
        if isCurrent { return .yellow }
        return isUncertain(point) ? .orange : .white.opacity(0.7)
    }

    private func isUncertain(_ point: TrackedPoint) -> Bool {
        !point.isManual && point.confidence < VideoTracker.uncertainConfidence
    }

    private var uncertainPointCount: Int {
        points.count(where: isUncertain)
    }
}
