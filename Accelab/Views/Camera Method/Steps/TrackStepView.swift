//
//  TrackStepView.swift
//  Accelab
//

import SwiftUI

struct TrackStepView: View {
    let method: Method
    let scrubber: VideoScrubber
    @Binding var points: [TrackedPoint]
    let onBack: () -> Void
    let onFinish: () -> Void

    @State private var mode: Mode
    @State private var isChromeHidden: Bool = false
    /// The box around the cart for automatic tracking, in pixels of the frame as it is shown.
    @State private var box: CGRect? = nil
    @State private var trackingTask: Task<Void, Never>? = nil
    @State private var didFailToTrack: Bool = false

    /// A distance–time curve needs at least this many samples to be worth exporting.
    private static let minimumPointCount = 3
    /// A smaller box gives the tracker too little to hold on to.
    static let minimumBoxSide: CGFloat = 20
    /// Trail markers closer together than this on screen are skipped, which keeps the trail readable
    /// and the number of glass shapes small.
    private static let minimumTrailMarkerSpacing: CGFloat = 14

    /// How far the clip moves on after each manual mark.
    private var markInterval: TimeInterval {
        switch method {
        case .camera, .sensor:
            return 0.1
        case .projectile:
            // A flight lasts well under a second, so a mark every tenth of a second would leave too few points.
            return 1.0 / 30
        }
    }

    private enum Mode {
        /// Nothing marked yet: the two ways of following the cart are offered.
        case choosing
        /// Drawing and adjusting the box that automatic tracking starts from.
        case drawingBox
        case tracking
        /// A tap on the video marks the cart.
        case marking
        /// Points exist and nothing is in progress: a tap on the video hides or shows the controls.
        case viewing
        /// Stepping through the points automatic tracking was unsure of.
        case reviewing
    }

    init(method: Method, scrubber: VideoScrubber, points: Binding<[TrackedPoint]>, onBack: @escaping () -> Void, onFinish: @escaping () -> Void) {
        self.method = method
        self.scrubber = scrubber
        self._points = points
        self.onBack = onBack
        self.onFinish = onFinish
        // Coming back to this step with points already marked skips the choice.
        self._mode = State(initialValue: points.wrappedValue.isEmpty ? .choosing : .viewing)
    }

    var body: some View {
        // Read here rather than inside the overlay, so the highlight follows the scrubber.
        let currentFrameIndex = scrubber.currentFrameIndex
        let isChromeHidden = isChromeHidden && (mode == .choosing || mode == .viewing || mode == .drawingBox)

        ZStack {
            VideoFrameViewer(scrubber: scrubber, onTap: handleTap) { mapping in
                // Beneath the trail and the reticle, so they stay on top of it.
                if method == .projectile, let origin = points.min(by: { $0.frameIndex < $1.frameIndex }) {
                    ProjectileAxes(xDirection: CGFloat(TrackGeometry.horizontalDirection(of: points)))
                        .position(mapping.viewPoint(for: origin.position))
                        .allowsHitTesting(false)
                }

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
                    TrackingBoxEditor(box: $box, mapping: mapping, onTapOutside: toggleChrome)
                }
            }

            if mode == .choosing {
                // The choice is the step's whole point until it is made, so it stays when the controls are hidden.
                methodChooser
                    .transition(.blurReplace)
            }

            VideoStepLayout(method: method, step: .track, instruction: instruction, isChromeHidden: isChromeHidden) {
                GlassEffectContainer {
                    HStack(spacing: 8) {
                        switch mode {
                        case .choosing:
                            EmptyView()
                        case .drawingBox:
                            boxControls
                        case .tracking:
                            trackingControls
                        case .marking, .viewing:
                            pointControls
                        case .reviewing:
                            reviewControls
                        }
                    }
                }
            } bottom: {
                // The points stay on the video; everything in this row is hidden with the rest.
                Group {
                    GlassIconButton(systemImage: "chevron.backward", label: "Back", isDisabled: mode == .tracking, perform: onBack)

                    VideoScrubBar(scrubber: scrubber, markedFrames: points.map(\.frameIndex), flaggedFrames: Set(points.filter(isUncertain).map(\.frameIndex)))
                        .disabled(mode == .tracking)

                    GlassIconButton(systemImage: "checkmark", label: "Finish", style: .prominent, isDisabled: !canFinish, perform: onFinish)
                }
                .hiddenWithChrome(isChromeHidden)
            }
        }
        .onChange(of: mode) {
            // A new mode has new controls to show, so it never starts with them hidden.
            withAnimation(.smooth) { self.isChromeHidden = false }
        }
        .onDisappear {
            trackingTask?.cancel()
        }
    }

    private var canFinish: Bool {
        (mode == .viewing || mode == .marking) && points.count >= Self.minimumPointCount
    }

    /// What to do right now, shown in the title card.
    private var instruction: LocalizedStringKey {
        let subject = method.subject
        let isProjectile = method == .projectile

        switch mode {
        case .choosing:
            return isProjectile ? "Go to the frame where the ball is launched, then choose how to follow it. Its first point becomes the origin." : "Go to the frame where the \(subject) is released, then choose how to follow it."
        case .drawingBox:
            if didFailToTrack { return "Couldn't follow the \(subject). Fit the box more tightly and press Start, or mark it by hand instead." }
            return box == nil ? "Drag a box around the \(subject) on this frame." : "Drag the corners until the box fits the \(subject) tightly, then press Start."
        case .tracking:
            return "Following the \(subject) through the video…"
        case .marking:
            if points.isEmpty { return isProjectile ? "Tap the centre of the ball." : "Tap the \(subject). Pick a spot you can find again on every frame." }
            if points.count < Self.minimumPointCount { return isProjectile ? "Tap the centre of the ball again. The video moves on after each tap." : "Tap the same spot again. The video moves on after each tap." }
            return isProjectile ? "Keep tapping the ball until the flight is covered, then press ✓." : "Keep tapping the same spot until the run is covered, then press ✓."
        case .viewing:
            return uncertainPointCount > 0 ? "^[\(uncertainPointCount) point](inflect: true) in orange may be off. Press Check to go through them." : "Scrub through to check the yellow trail follows the \(subject), then press ✓."
        case .reviewing:
            return "Is the ring on the \(subject)? Tap where the \(subject) really is, or press Keep if it's right."
        }
    }

    // MARK: - Controls

    /// The two ways of following the cart, offered side by side before anything is marked.
    private var methodChooser: some View {
        GlassEffectContainer {
            HStack(spacing: 12) {
                methodCard(systemImage: "scope", title: "Track Automatically", detail: "Draw a box around the \(method.subject) and Accelab follows it.", isRecommended: true) {
                    withAnimation { self.mode = .drawingBox }
                }

                methodCard(systemImage: "hand.tap", title: "Mark by Hand", detail: "Tap the \(method.subject) yourself, frame by frame.", isRecommended: false) {
                    withAnimation { self.mode = .marking }
                }
            }
        }
        .padding(.horizontal)
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
        .environment(\.colorScheme, .dark)
    }

    private func methodCard(systemImage: String, title: String, detail: String, isRecommended: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.prominentTap()
            action()
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: systemImage)
                    .customFont(.title2, weight: .semibold)
                    // Not the method's own colour: the projectile's is too dark to read on dark glass.
                    .foregroundStyle(isRecommended ? .white : .green1)
                    .padding(.bottom, 2)

                Text(title)
                    .customFont(.subheadline, weight: .bold)

                Text(detail)
                    .customFont(.caption)
                    .opacity(0.8)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(.white)
            .frame(width: 190, alignment: .leading)
            .padding(14)
            .contentShape(.rect(cornerRadius: 22))
            .glassEffect(isRecommended ? .regular.tint(.accentColor).interactive() : .regular.interactive(), in: .rect(cornerRadius: 22))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var boxControls: some View {
        // Titled, because a bare ✕ beside the box read as "delete the box" rather than "leave this mode".
        GlassIconButton(systemImage: "xmark", title: "Cancel", label: "Cancel Automatic Tracking") {
            self.box = nil
            self.didFailToTrack = false
            withAnimation { self.mode = points.isEmpty ? .choosing : .viewing }
        }

        GlassIconButton(systemImage: "play.fill", title: "Start", label: "Start Tracking", style: .prominent, isDisabled: box == nil, perform: startTracking)
    }

    @ViewBuilder
    private var trackingControls: some View {
        GlassStatusLabel {
            HStack(spacing: 8) {
                ProgressView()

                Text("^[\(points.count) point](inflect: true)")
            }
        }

        GlassIconButton(systemImage: "stop.fill", label: "Stop Tracking") {
            trackingTask?.cancel()
        }
    }

    /// Shown once there are points, or while marking by hand.
    @ViewBuilder
    private var pointControls: some View {
        GlassStatusLabel {
            Label("^[\(points.count) point](inflect: true)", systemImage: mode == .marking ? "hand.tap" : "scope")
                .contentTransition(.numericText(value: Double(points.count)))
        }

        if mode == .viewing && uncertainPointCount > 0 {
            GlassIconButton(systemImage: "exclamationmark.circle.fill", title: "Check \(uncertainPointCount)", label: "Check Uncertain Points", style: .prominent, perform: startReviewing)
        }

        if mode == .marking {
            GlassIconButton(systemImage: "arrow.uturn.backward", label: "Undo Last Point", isDisabled: points.isEmpty, perform: undo)
        }

        Menu {
            if mode == .marking {
                Button("Stop Marking by Hand", systemImage: "hand.raised") { withAnimation { self.mode = points.isEmpty ? .choosing : .viewing } }
            } else {
                Button("Mark by Hand", systemImage: "hand.tap") { withAnimation { self.mode = .marking } }
            }
            Button("Track Automatically from This Frame", systemImage: "scope") {
                self.didFailToTrack = false
                withAnimation { self.mode = .drawingBox }
            }

            Divider()

            Button("Remove Points Before This Frame", systemImage: "arrow.left.to.line") { removePoints(keeping: { $0 >= scrubber.currentFrameIndex }) }
            Button("Remove Points After This Frame", systemImage: "arrow.right.to.line") { removePoints(keeping: { $0 <= scrubber.currentFrameIndex }) }
            Button("Clear All Points", systemImage: "trash", role: .destructive, action: clear)
        } label: {
            GlassIconLabel(systemImage: "ellipsis")
        }
        .buttonStyle(.plain)
        .accessibilityLabel("More")
    }

    @ViewBuilder
    private var reviewControls: some View {
        GlassStatusLabel {
            Label("\(uncertainPointCount) left", systemImage: "exclamationmark.circle.fill")
                .foregroundStyle(.orange)
                .contentTransition(.numericText(value: Double(uncertainPointCount)))
        }

        GlassIconButton(systemImage: "checkmark", title: "Keep", label: "Keep This Point", style: .prominent, perform: keepCurrentPoint)

        GlassIconButton(systemImage: "xmark", label: "Stop Checking") {
            withAnimation { self.mode = .viewing }
        }
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

    // MARK: - Actions

    /// A tap on the video marks the cart while marking or checking, and otherwise hides or shows the
    /// controls, as in a video player.
    private func handleTap(at position: CGPoint) {
        let isOnVideo = scrubber.frames.map { CGRect(origin: .zero, size: $0.displaySize).contains(position) } ?? false

        switch mode {
        case .choosing, .viewing, .drawingBox:
            toggleChrome()
        case .marking:
            if isOnVideo {
                mark(at: position)
                scrubber.step(bySeconds: markInterval)
            }
        case .reviewing:
            if isOnVideo {
                mark(at: position)
                goToNextUncertainPoint()
            }
        case .tracking:
            break
        }
    }

    private func toggleChrome() {
        withAnimation(.smooth) { self.isChromeHidden.toggle() }
    }

    /// Marks the cart on the current frame, replacing an earlier mark on it.
    private func mark(at position: CGPoint) {
        let frameIndex = scrubber.currentFrameIndex
        Haptics.tap()

        withAnimation {
            self.points.removeAll { $0.frameIndex == frameIndex }
            self.points.append(TrackedPoint(frameIndex: frameIndex, position: position))
            self.points.sort { $0.frameIndex < $1.frameIndex }
        }
    }

    /// Follows the boxed cart from the current frame to the end of the kept range, replacing any points already there.
    private func startTracking() {
        guard let box, let frames = scrubber.frames else { return }

        let startFrame = scrubber.currentFrameIndex
        self.points.removeAll { $0.frameIndex >= startFrame }
        self.didFailToTrack = false
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
            if trackedCount < 2 && !Task.isCancelled {
                // Back to the box, which is kept, so it can be adjusted and tried again.
                self.points.removeAll { $0.frameIndex >= startFrame }
                self.didFailToTrack = true
                Haptics.error()
                scrubber.seek(toFrame: startFrame)
                withAnimation { self.mode = .drawingBox }
                return
            }

            self.box = nil
            if let last = points.last {
                scrubber.seek(toFrame: last.frameIndex)
            }
            // A warning rather than a success when some of the points need checking.
            if points.contains(where: isUncertain) { Haptics.warning() } else { Haptics.success() }
            withAnimation { self.mode = .viewing }
        }
    }

    // MARK: Checking uncertain points

    private func startReviewing() {
        guard let first = points.first(where: isUncertain) else { return }

        scrubber.seek(toFrame: first.frameIndex)
        withAnimation { self.mode = .reviewing }
    }

    /// Accepts the tracked position on the current frame as it is.
    private func keepCurrentPoint() {
        if let index = points.firstIndex(where: { $0.frameIndex == scrubber.currentFrameIndex }) {
            self.points[index].confidence = 1
        }

        goToNextUncertainPoint()
    }

    /// Moves to the next point that still needs checking, or leaves checking when none is left.
    private func goToNextUncertainPoint() {
        let current = scrubber.currentFrameIndex
        let remaining = points.filter(isUncertain)

        if let next = remaining.first(where: { $0.frameIndex > current }) ?? remaining.first {
            scrubber.seek(toFrame: next.frameIndex)
        } else {
            withAnimation { self.mode = .viewing }
        }
    }

    // MARK: Editing points

    /// Removes every mark and returns to where marking began, with the choice of method offered again.
    private func clear() {
        guard let first = points.first else { return }

        scrubber.seek(toFrame: first.frameIndex)
        withAnimation {
            self.points = []
            self.mode = .choosing
        }
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
            if points.isEmpty && mode == .viewing {
                self.mode = .choosing
            }
        }
    }

    private func isUncertain(_ point: TrackedPoint) -> Bool {
        !point.isManual && point.confidence < VideoTracker.uncertainConfidence
    }

    private var uncertainPointCount: Int {
        points.count(where: isUncertain)
    }
}

/// The origin and the two axes a projectile's x and y are measured along, drawn at a constant size around
/// the point it is placed on. Not glass, because the origin is a spot to be read exactly.
private struct ProjectileAxes: View {
    /// 1 when x counts up towards the right of the picture, -1 towards the left.
    let xDirection: CGFloat

    /// How long each axis is on screen, whatever the zoom.
    private static let length: CGFloat = 56
    /// How far past an arrow's tip the middle of its label sits.
    private static let labelGap: CGFloat = 12
    private static let labelSize: CGFloat = 16

    var body: some View {
        let reach = (Self.length + Self.labelGap) * 2 + 8
        // The picture's y runs downwards, so height counts up the screen towards negative y.
        let xAxis = CGVector(dx: xDirection, dy: 0)
        let yAxis = CGVector(dx: 0, dy: -1)

        ZStack {
            arrow(direction: xAxis)
            arrow(direction: yAxis)
            label("x", direction: xAxis)
            label("y", direction: yAxis)
        }
        .frame(width: reach, height: reach)
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Origin and axes")
    }

    /// A thin white line with a dark outline beneath it, so it reads over light and dark footage alike.
    private func arrow(direction: CGVector) -> some View {
        ZStack {
            AxisArrow(direction: direction, length: Self.length)
                .stroke(.black.opacity(0.5), style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))

            AxisArrow(direction: direction, length: Self.length)
                .stroke(.white, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        }
    }

    /// The axis's name on a dark disc: white text alone, even with a shadow, is lost over light footage.
    private func label(_ name: String, direction: CGVector) -> some View {
        Text(verbatim: name)
            .customFont(.caption2, weight: .bold)
            .foregroundStyle(.white)
            .frame(width: Self.labelSize, height: Self.labelSize)
            .background(.black.opacity(0.55), in: .circle)
            .offset(x: direction.dx * (Self.length + Self.labelGap), y: direction.dy * (Self.length + Self.labelGap))
    }
}

/// A line from the middle of its rect, `length` long in `direction`, ending in an arrowhead.
private struct AxisArrow: Shape {
    let direction: CGVector
    let length: CGFloat

    private static let headLength: CGFloat = 8
    /// How far each barb of the arrowhead leans back from the line, in radians (about 29°).
    private static let headAngle: CGFloat = 0.5

    func path(in rect: CGRect) -> Path {
        let start = CGPoint(x: rect.midX, y: rect.midY)
        let tip = CGPoint(x: start.x + direction.dx * length, y: start.y + direction.dy * length)
        // The way back from the tip along the line, turned to either side for the two barbs.
        let back = atan2(-direction.dy, -direction.dx)

        var path = Path()
        path.move(to: start)
        path.addLine(to: tip)

        for turn in [-Self.headAngle, Self.headAngle] {
            path.move(to: tip)
            path.addLine(to: CGPoint(x: tip.x + Self.headLength * cos(back + turn), y: tip.y + Self.headLength * sin(back + turn)))
        }

        return path
    }
}

/// The box automatic tracking starts from. Dragged out once, then moved by its body and resized by its corners.
private struct TrackingBoxEditor: View {
    @Binding var box: CGRect?
    let mapping: VideoViewMapping
    /// Called for a tap that isn't on the box, before one has been drawn.
    let onTapOutside: () -> Void

    /// The box as it was when the current move or resize began.
    @State private var boxAtDragStart: CGRect? = nil

    private enum Corner: CaseIterable {
        case topLeft, topRight, bottomRight, bottomLeft

        func point(of rect: CGRect) -> CGPoint {
            switch self {
            case .topLeft: return CGPoint(x: rect.minX, y: rect.minY)
            case .topRight: return CGPoint(x: rect.maxX, y: rect.minY)
            case .bottomRight: return CGPoint(x: rect.maxX, y: rect.maxY)
            case .bottomLeft: return CGPoint(x: rect.minX, y: rect.maxY)
            }
        }

        var opposite: Corner {
            switch self {
            case .topLeft: return .bottomRight
            case .topRight: return .bottomLeft
            case .bottomRight: return .topLeft
            case .bottomLeft: return .topRight
            }
        }
    }

    var body: some View {
        if let box {
            let topLeft = mapping.viewPoint(for: box.origin)
            let bottomRight = mapping.viewPoint(for: CGPoint(x: box.maxX, y: box.maxY))

            ZStack {
                // The inside is left untouched so the cart stays sharp. Dragging it moves the box.
                RoundedRectangle(cornerRadius: 4)
                    .stroke(.black.opacity(0.5), lineWidth: 3.5)
                    .stroke(.yellow, lineWidth: 2)
                    .frame(width: max(bottomRight.x - topLeft.x, 1), height: max(bottomRight.y - topLeft.y, 1))
                    .contentShape(.rect)
                    .position(x: (topLeft.x + bottomRight.x) / 2, y: (topLeft.y + bottomRight.y) / 2)
                    .gesture(dragGesture { original, delta in
                        let x = min(max(original.minX + delta.width, 0), mapping.videoSize.width - original.width)
                        let y = min(max(original.minY + delta.height, 0), mapping.videoSize.height - original.height)
                        return CGRect(x: x, y: y, width: original.width, height: original.height)
                    })
                    .accessibilityLabel("Tracking box")

                GlassEffectContainer(spacing: 0) {
                    ZStack {
                        ForEach(Corner.allCases, id: \.self) { corner in
                            Circle()
                                .fill(.clear)
                                .frame(width: 16, height: 16)
                                .glassEffect(.regular.tint(.yellow).interactive(), in: .circle)
                                // Easier to grab than it looks.
                                .frame(width: 40, height: 40)
                                .contentShape(.rect)
                                .position(mapping.viewPoint(for: corner.point(of: box)))
                                .gesture(dragGesture { original, delta in
                                    let fixed = corner.opposite.point(of: original)
                                    let start = corner.point(of: original)
                                    let moved = mapping.clamped(CGPoint(x: start.x + delta.width, y: start.y + delta.height))
                                    let resized = CGRect(x: min(fixed.x, moved.x), y: min(fixed.y, moved.y), width: abs(moved.x - fixed.x), height: abs(moved.y - fixed.y))
                                    return min(resized.width, resized.height) >= TrackStepView.minimumBoxSide ? resized : nil
                                })
                                .accessibilityLabel("Box corner")
                        }
                    }
                }
            }
        } else {
            // Nothing drawn yet: a drag anywhere draws the box.
            Color.clear
                .contentShape(.rect)
                .onTapGesture(perform: onTapOutside)
                .gesture(
                    DragGesture(minimumDistance: 4, coordinateSpace: VideoViewMapping.coordinateSpace)
                        .onChanged { value in
                            let start = mapping.clamped(mapping.videoPoint(for: value.startLocation))
                            let end = mapping.clamped(mapping.videoPoint(for: value.location))
                            self.boxAtDragStart = CGRect(x: min(start.x, end.x), y: min(start.y, end.y), width: abs(end.x - start.x), height: abs(end.y - start.y))
                        }
                        .onEnded { _ in
                            // Committed only once the finger lifts, and only if it is big enough to track.
                            if let drawn = boxAtDragStart, min(drawn.width, drawn.height) >= TrackStepView.minimumBoxSide {
                                self.box = drawn
                                Haptics.tap()
                            }
                            self.boxAtDragStart = nil
                        }
                )
                .overlay {
                    if let drawing = boxAtDragStart {
                        let topLeft = mapping.viewPoint(for: drawing.origin)
                        let bottomRight = mapping.viewPoint(for: CGPoint(x: drawing.maxX, y: drawing.maxY))

                        RoundedRectangle(cornerRadius: 4)
                            .stroke(.black.opacity(0.5), lineWidth: 3.5)
                            .stroke(.yellow, lineWidth: 2)
                            .frame(width: max(bottomRight.x - topLeft.x, 1), height: max(bottomRight.y - topLeft.y, 1))
                            .position(x: (topLeft.x + bottomRight.x) / 2, y: (topLeft.y + bottomRight.y) / 2)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    /// A drag that changes the box from how it was when the drag began. `change` gets that box and how far
    /// the finger has moved, in video pixels, and returns the new box, or `nil` to leave it as it is.
    private func dragGesture(_ change: @escaping (_ original: CGRect, _ delta: CGSize) -> CGRect?) -> some Gesture {
        DragGesture(coordinateSpace: VideoViewMapping.coordinateSpace)
            .onChanged { value in
                guard let original = boxAtDragStart ?? box else { return }
                self.boxAtDragStart = original

                let origin = mapping.videoPoint(for: .zero)
                let moved = mapping.videoPoint(for: CGPoint(x: value.translation.width, y: value.translation.height))
                if let changed = change(original, CGSize(width: moved.x - origin.x, height: moved.y - origin.y)) {
                    self.box = changed
                }
            }
            .onEnded { _ in
                self.boxAtDragStart = nil
                Haptics.tap()
            }
    }
}
