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
    /// Trail markers closer together than this on screen are skipped, which keeps the trail readable
    /// and the number of glass shapes small.
    private static let minimumTrailMarkerSpacing: CGFloat = 14

    private enum Mode {
        case marking, drawingBox, tracking
    }

    var body: some View {
        // Read here rather than inside the overlay, so the highlight follows the scrubber.
        let currentFrameIndex = scrubber.currentFrameIndex
        let onTap: ((CGPoint) -> Void)? = mode == .marking ? { mark(at: $0) } : nil

        ZStack {
            VideoFrameViewer(scrubber: scrubber, onTap: onTap) { mapping in
                // No blending distance, so neighbouring markers stay separate beads instead of merging.
                GlassEffectContainer(spacing: 0) {
                    ZStack {
                        ForEach(trailPoints(currentFrameIndex: currentFrameIndex, mapping: mapping)) { point in
                            trailMarker(for: point)
                                .position(mapping.viewPoint(for: point.position))
                        }
                    }
                }
                .allowsHitTesting(false)

                if let currentPoint = points.first(where: { $0.frameIndex == currentFrameIndex }) {
                    // Not glass, which would bend the very spot being checked.
                    Reticle(size: 22)
                        .position(mapping.viewPoint(for: currentPoint.position))
                        .allowsHitTesting(false)
                }

                if mode == .drawingBox {
                    boxDrawingLayer(mapping: mapping)
                }
            }

            VideoStepLayout(step: .track) {
                GlassEffectContainer {
                    VStack(alignment: .trailing, spacing: 8) {
                        switch mode {
                        case .marking:
                            markingControls
                        case .drawingBox:
                            boxControls
                        case .tracking:
                            trackingControls
                        }
                    }
                }
            } bottom: {
                GlassButton(text: "Back", style: .secondary, isDisabled: mode == .tracking, perform: onBack)

                VideoScrubBar(scrubber: scrubber)
                    .disabled(mode == .tracking)

                GlassButton(text: "Finish", isDisabled: mode != .marking || points.count < Self.minimumPointCount, perform: onFinish)
            }
        }
        .onDisappear {
            trackingTask?.cancel()
        }
    }

    // MARK: - Controls

    @ViewBuilder
    private var markingControls: some View {
        HStack(spacing: 8) {
            Text("^[\(points.count) point](inflect: true)")
                .customFont(.subheadline, weight: .bold)
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(points.count)))
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .glassEffect(.regular, in: .capsule)

            GlassButton(text: "Auto-Track", textFont: .subheadline) {
                self.didFailToTrack = false
                withAnimation { self.mode = .drawingBox }
            }
            .fixedSize()

            Menu {
                Button("Undo Last Point", systemImage: "arrow.uturn.backward", action: undo)
                Button("Remove Points Before This Frame", systemImage: "arrow.left.to.line") { removePoints(keeping: { $0 >= scrubber.currentFrameIndex }) }
                Button("Remove Points After This Frame", systemImage: "arrow.right.to.line") { removePoints(keeping: { $0 <= scrubber.currentFrameIndex }) }
                Button("Clear All Points", systemImage: "trash", role: .destructive, action: clear)
            } label: {
                Image(systemName: "ellipsis")
                    .customFont(.subheadline, weight: .bold)
                    .frame(width: 22, height: 26)
            }
            .buttonStyle(.glass)
            .disabled(points.isEmpty)
            .accessibilityLabel("Edit Points")
        }

        if didFailToTrack {
            hint("Couldn't follow the cart. Try a tighter box, or tap it by hand.", systemImage: "exclamationmark.triangle.fill", color: .red)
        } else if uncertainPointCount > 0 {
            hint("^[\(uncertainPointCount) orange point](inflect: true) may be off. Tap the cart on that frame to fix it.", systemImage: "exclamationmark.circle.fill", color: .orange)
        }
    }

    @ViewBuilder
    private var boxControls: some View {
        HStack(spacing: 8) {
            GlassButton(text: "Cancel", style: .secondary, textFont: .subheadline) {
                self.box = nil
                withAnimation { self.mode = .marking }
            }

            GlassButton(text: "Start", textFont: .subheadline, isDisabled: box == nil, perform: startTracking)
        }
        .fixedSize()

        hint("Drag a box tightly around the cart on this frame.", systemImage: "rectangle.dashed", color: .primary)
    }

    @ViewBuilder
    private var trackingControls: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                ProgressView()

                Text("Tracking… ^[\(points.count) point](inflect: true)")
                    .customFont(.subheadline, weight: .bold)
                    .monospacedDigit()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .glassEffect(.regular, in: .capsule)

            GlassButton(text: "Stop", style: .secondary, textFont: .subheadline) {
                trackingTask?.cancel()
            }
        }
        .fixedSize()
    }

    private func hint(_ text: LocalizedStringKey, systemImage: String, color: Color) -> some View {
        Label(text, systemImage: systemImage)
            .customFont(.caption, weight: .medium)
            .foregroundStyle(color)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 260, alignment: .leading)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
            .transition(.blurReplace)
    }

    // MARK: - Markers

    private func trailMarker(for point: TrackedPoint) -> some View {
        Circle()
            .fill(.clear)
            .frame(width: 10, height: 10)
            .glassEffect(.regular.tint(isUncertain(point) ? .orange : .yellow.opacity(0.7)), in: .circle)
    }

    /// The points drawn as the trail: spaced out on screen, always keeping the uncertain ones.
    /// The current frame's point is drawn separately.
    private func trailPoints(currentFrameIndex: Int, mapping: VideoViewMapping) -> [TrackedPoint] {
        var lastKept: CGPoint? = nil

        return points.filter { point in
            guard point.frameIndex != currentFrameIndex else { return false }

            let viewPoint = mapping.viewPoint(for: point.position)
            if let lastKept, hypot(viewPoint.x - lastKept.x, viewPoint.y - lastKept.y) < Self.minimumTrailMarkerSpacing, !isUncertain(point) {
                return false
            }

            lastKept = viewPoint
            return true
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

                // The inside is left untouched so the cart stays sharp; only the corners are glass.
                RoundedRectangle(cornerRadius: 4)
                    .stroke(.black.opacity(0.5), lineWidth: 3.5)
                    .stroke(.yellow, lineWidth: 2)
                    .frame(width: max(bottomRight.x - topLeft.x, 1), height: max(bottomRight.y - topLeft.y, 1))
                    .position(x: (topLeft.x + bottomRight.x) / 2, y: (topLeft.y + bottomRight.y) / 2)
                    .allowsHitTesting(false)

                GlassEffectContainer(spacing: 0) {
                    ZStack {
                        ForEach([topLeft, CGPoint(x: bottomRight.x, y: topLeft.y), bottomRight, CGPoint(x: topLeft.x, y: bottomRight.y)], id: \.debugDescription) { corner in
                            Circle()
                                .fill(.clear)
                                .frame(width: 12, height: 12)
                                .glassEffect(.regular.tint(.yellow), in: .circle)
                                .position(corner)
                        }
                    }
                }
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

    /// Follows the boxed cart from the current frame to the end of the kept range, replacing any points already there.
    private func startTracking() {
        guard let box, let frames = scrubber.frames else { return }

        let startFrame = scrubber.currentFrameIndex
        self.points.removeAll { $0.frameIndex >= startFrame }
        self.box = nil
        withAnimation { self.mode = .tracking }

        self.trackingTask = Task {
            var trackedCount = 0

            do {
                for try await point in VideoTracker.track(url: scrubber.url, frames: frames, startFrame: startFrame, endFrame: scrubber.trimRange.upperBound, box: box) {
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

    private func removePoints(keeping shouldKeep: (Int) -> Bool) {
        withAnimation {
            self.points.removeAll { !shouldKeep($0.frameIndex) }
        }
    }

    private func isUncertain(_ point: TrackedPoint) -> Bool {
        !point.isManual && point.confidence < VideoTracker.uncertainConfidence
    }

    private var uncertainPointCount: Int {
        points.count(where: isUncertain)
    }
}
