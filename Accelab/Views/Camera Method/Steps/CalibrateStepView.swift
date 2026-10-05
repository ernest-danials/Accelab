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
                    let startInView = mapping.viewPoint(for: start)
                    let endInView = mapping.viewPoint(for: end)

                    Path { path in
                        path.move(to: startInView)
                        path.addLine(to: endInView)
                    }
                    .stroke(.yellow, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                    .shadow(color: .black.opacity(0.4), radius: 1)
                    .allowsHitTesting(false)

                    GlassEffectContainer {
                        ZStack {
                            CalibrationHandle(point: Binding(get: { start }, set: { self.start = $0 }), mapping: mapping)
                            CalibrationHandle(point: Binding(get: { end }, set: { self.end = $0 }), mapping: mapping)
                        }
                    }
                }
            }

            VideoStepLayout(step: .calibrate) {
                VStack(alignment: .trailing, spacing: 8) {
                    lengthField

                    if isReferenceTooShort {
                        Label("Use a longer reference", systemImage: "exclamationmark.triangle.fill")
                            .customFont(.caption, weight: .medium)
                            .foregroundStyle(.yellow)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .glassEffect(.regular, in: .capsule)
                            .transition(.blurReplace)
                    }
                }
                .animation(.smooth, value: isReferenceTooShort)
            } bottom: {
                GlassButton(text: "Back", style: .secondary, perform: onBack)

                VideoScrubBar(scrubber: scrubber)

                GlassButton(text: "Continue", isDisabled: currentCalibration == nil) {
                    if let currentCalibration {
                        onContinue(currentCalibration)
                    }
                }
            }
        }
        .ignoresSafeArea(.keyboard)
        .task(id: scrubber.frameCount) {
            placeMarkersIfNeeded()
        }
    }

    private var lengthField: some View {
        HStack(spacing: 8) {
            Image(systemName: "ruler")
                .customFont(.subheadline, weight: .medium)
                .foregroundStyle(.secondary)

            TextField("100", text: $lengthText)
                .keyboardType(.decimalPad)
                .focused($isLengthFieldFocused)
                .multilineTextAlignment(.trailing)
                .customFont(.headline, weight: .bold)
                .frame(width: 64)
                .accessibilityLabel("Known length in centimetres")

            Text("cm")
                .customFont(.subheadline, weight: .medium)

            if isLengthFieldFocused {
                Button("Done") {
                    self.isLengthFieldFocused = false
                }
                .customFont(.subheadline, weight: .bold)
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
        .glassEffect(.regular.interactive(), in: .capsule)
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
        return hypot(end.x - start.x, end.y - start.y) < max(videoSize.width, videoSize.height) * Self.minimumLengthFraction
    }

    /// `nil` until the markers and the length make a usable scale.
    private var currentCalibration: CameraCalibration? {
        guard let start, let end, let lengthInMeters, !isReferenceTooShort else { return nil }
        return CameraCalibration(start: start, end: end, lengthInMeters: lengthInMeters)
    }
}

/// A ring with a dot at its centre, for pointing at an exact spot on the clip without covering it.
struct Reticle: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(.black.opacity(0.5), lineWidth: 3.5)

            Circle()
                .stroke(.yellow, lineWidth: 2)

            Circle()
                .fill(.yellow)
                .stroke(.black.opacity(0.5), lineWidth: 0.5)
                .frame(width: 4, height: 4)
        }
        .frame(width: size, height: size)
    }
}

/// A marker whose grip sits beside the point it marks, so the finger doesn't cover the point.
private struct CalibrationHandle: View {
    @Binding var point: CGPoint
    let mapping: VideoViewMapping

    /// Where the point was when the current drag began.
    @State private var pointAtDragStart: CGPoint? = nil

    private static let gripDistance: CGFloat = 44
    private static let gripSize: CGFloat = 36
    private static let lensSize: CGFloat = 26

    var body: some View {
        let viewPoint = mapping.viewPoint(for: point)
        // Flipped in the lower part of the screen, where a grip below the point would sit under the controls.
        let gripOffset = viewPoint.y > mapping.containerSize.height * 0.6 ? -Self.gripDistance : Self.gripDistance

        ZStack {
            Capsule()
                .fill(.yellow)
                .frame(width: 2, height: Self.gripDistance - Self.lensSize / 2 - Self.gripSize / 2)
                .offset(y: gripOffset / 2 + (gripOffset > 0 ? 1 : -1) * (Self.lensSize - Self.gripSize) / 4)

            // Deliberately not glass: glass bends what is behind it, and this is where the exact spot is read.
            Reticle(size: Self.lensSize)

            Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                .customFont(.caption, weight: .bold)
                .foregroundStyle(.black.opacity(0.7))
                .frame(width: Self.gripSize, height: Self.gripSize)
                .glassEffect(.regular.tint(.yellow).interactive(), in: .circle)
                .offset(y: gripOffset)
        }
        .frame(width: 48, height: 2 * Self.gripDistance + Self.gripSize)
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
        .accessibilityLabel("Marker")
    }
}
