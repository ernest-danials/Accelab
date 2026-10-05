//
//  CalibrateStepView.swift
//  Accelab
//

import SwiftUI

struct CalibrateStepView: View {
    let scrubber: VideoScrubber
    /// The calibration to start from when the user comes back to this step.
    let calibration: CameraCalibration?
    let onBack: () -> Void
    let onContinue: (CameraCalibration) -> Void

    @State private var start: CGPoint? = nil
    @State private var end: CGPoint? = nil
    @State private var lengthText: String = "100"
    @FocusState private var isLengthFieldFocused: Bool

    /// A shorter reference makes the scale too sensitive to where the markers are placed.
    private static let minimumLengthFraction: Double = 0.15

    var body: some View {
        ZStack {
            VideoFrameViewer(scrubber: scrubber) { mapping in
                if let start, let end {
                    Path { path in
                        path.move(to: mapping.viewPoint(for: start))
                        path.addLine(to: mapping.viewPoint(for: end))
                    }
                    .stroke(.yellow, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                    .allowsHitTesting(false)

                    CalibrationHandle(point: Binding(get: { start }, set: { self.start = $0 }), mapping: mapping)
                    CalibrationHandle(point: Binding(get: { end }, set: { self.end = $0 }), mapping: mapping)
                }
            }
            .containerRelativeFrame(.horizontal) { width, _ in width * 0.6 }
            .padding(.top)
            .padding(.bottom, 70)
            .alignView(to: .trailing)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Length")
                        .customFont(.subheadline, weight: .medium)

                    TextField("100", text: $lengthText)
                        .keyboardType(.decimalPad)
                        .focused($isLengthFieldFocused)
                        .multilineTextAlignment(.trailing)
                        .customFont(.title3, weight: .bold)
                        .frame(width: 80)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .glassEffect(.regular, in: .capsule)

                    Text("cm")
                        .customFont(.subheadline, weight: .medium)

                    if isLengthFieldFocused {
                        GlassButton(text: "Done", style: .secondary, textFont: .subheadline) {
                            self.isLengthFieldFocused = false
                        }
                    }
                }

                if isReferenceTooShort {
                    Label("Use a longer reference. A short one makes the scale inaccurate.", systemImage: "exclamationmark.triangle.fill")
                        .customFont(.caption, weight: .medium)
                        .foregroundStyle(.yellow)
                } else {
                    Text("Pinch to zoom in and place the markers precisely.")
                        .customFont(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 260, alignment: .leading)
            .padding(.horizontal, 30)
            .alignView(to: .leading)
            .offset(y: 30)

            HStack {
                GlassButton(text: "Back", style: .secondary, perform: onBack)

                GlassButton(text: "Continue", isDisabled: currentCalibration == nil) {
                    if let currentCalibration {
                        onContinue(currentCalibration)
                    }
                }
            }
            .alignView(to: .trailing)
            .alignViewVertically(to: .bottom)
            .padding()
        }
        .ignoresSafeArea(.keyboard)
        .task(id: scrubber.frameCount) {
            placeMarkersIfNeeded()
        }
    }

    private func placeMarkersIfNeeded() {
        guard start == nil, let videoSize = scrubber.frames?.displaySize else { return }

        if let calibration {
            self.start = calibration.start
            self.end = calibration.end
            self.lengthText = String(format: "%g", calibration.lengthInMeters * 100)
        } else {
            self.start = CGPoint(x: videoSize.width * 0.3, y: videoSize.height * 0.5)
            self.end = CGPoint(x: videoSize.width * 0.7, y: videoSize.height * 0.5)
        }
    }

    private var lengthInMeters: Double? {
        guard let centimeters = Double(lengthText.replacingOccurrences(of: ",", with: ".")), centimeters > 0 else { return nil }
        return centimeters / 100
    }

    private var isReferenceTooShort: Bool {
        guard let start, let end, let videoSize = scrubber.frames?.displaySize else { return false }
        return hypot(end.x - start.x, end.y - start.y) < videoSize.width * Self.minimumLengthFraction
    }

    /// `nil` until the markers and the length make a usable scale.
    private var currentCalibration: CameraCalibration? {
        guard let start, let end, let lengthInMeters, !isReferenceTooShort else { return nil }
        return CameraCalibration(start: start, end: end, lengthInMeters: lengthInMeters)
    }
}

/// A marker whose grip sits beside the point it marks, so the finger doesn't cover the point.
private struct CalibrationHandle: View {
    @Binding var point: CGPoint
    let mapping: VideoViewMapping

    /// Where the point was when the current drag began.
    @State private var pointAtDragStart: CGPoint? = nil

    private static let gripDistance: CGFloat = 40

    var body: some View {
        let viewPoint = mapping.viewPoint(for: point)
        // Flipped near the bottom edge, where a grip below the point would be cut off.
        let gripOffset = viewPoint.y > mapping.containerSize.height - Self.gripDistance - 20 ? -Self.gripDistance : Self.gripDistance

        ZStack {
            Rectangle()
                .fill(.yellow)
                .frame(width: 2, height: abs(gripOffset))
                .offset(y: gripOffset / 2)

            Circle()
                .stroke(.yellow, lineWidth: 2)
                .frame(width: 16, height: 16)

            Circle()
                .fill(.yellow)
                .frame(width: 3, height: 3)

            Circle()
                .fill(.yellow)
                .stroke(.black.opacity(0.4), lineWidth: 1)
                .frame(width: 30, height: 30)
                .offset(y: gripOffset)
        }
        .frame(width: 44, height: 2 * Self.gripDistance + 44)
        .contentShape(.rect)
        .position(viewPoint)
        .gesture(
            DragGesture(coordinateSpace: VideoViewMapping.coordinateSpace)
                .onChanged { value in
                    let origin = pointAtDragStart ?? point
                    self.pointAtDragStart = origin

                    let originInView = mapping.viewPoint(for: origin)
                    self.point = mapping.clamped(mapping.videoPoint(for: CGPoint(x: originInView.x + value.translation.width, y: originInView.y + value.translation.height)))
                }
                .onEnded { _ in
                    self.pointAtDragStart = nil
                }
        )
    }
}
