//
//  CalibrateStepView.swift
//  Accelab
//

import SwiftUI

struct CalibrateStepView: View {
    let method: Method
    let scrubber: VideoScrubber
    /// The calibration to start from when the user comes back to this step.
    let calibration: CameraCalibration?
    let onBack: () -> Void
    let onContinue: (CameraCalibration) -> Void

    @State private var start: CGPoint? = nil
    @State private var end: CGPoint? = nil
    @State private var lengthText: String = "100"
    @FocusState private var isLengthFieldFocused: Bool
    @State private var isChromeHidden: Bool = false

    /// A shorter reference makes the scale too sensitive to where the markers are placed.
    private static let minimumLengthFraction: Double = 0.15

    var body: some View {
        ZStack {
            VideoFrameViewer(scrubber: scrubber, onTap: { _ in
                // A tap on the video puts the keyboard away first, and only otherwise hides the controls.
                if isLengthFieldFocused {
                    self.isLengthFieldFocused = false
                } else {
                    withAnimation(.smooth) { self.isChromeHidden.toggle() }
                }
            }) { mapping in
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

                    lengthIndicator(from: startInView, to: endInView)

                    GlassEffectContainer {
                        ZStack {
                            CalibrationHandle(point: Binding(get: { start }, set: { self.start = $0 }), mapping: mapping)
                            CalibrationHandle(point: Binding(get: { end }, set: { self.end = $0 }), mapping: mapping)
                        }
                    }
                }
            }

            VideoStepLayout(method: method, step: .calibrate, instruction: "Drag each yellow marker onto one end of a length you know, then enter that length.", isChromeHidden: isChromeHidden) {
                VStack(alignment: .trailing, spacing: 8) {
                    lengthField

                    if isReferenceTooShort {
                        GlassStatusLabel {
                            Label("Use a longer reference", systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.yellow)
                        }
                        .transition(.blurReplace)
                    }
                }
                .animation(.smooth, value: isReferenceTooShort)
            } bottom: {
                // The markers stay on the video; everything in this row is hidden with the rest.
                Group {
                    GlassIconButton(systemImage: "chevron.backward", label: "Back", perform: onBack)

                    VideoScrubBar(scrubber: scrubber)

                    GlassIconButton(systemImage: "arrow.forward", label: "Continue", style: .prominent, isDisabled: currentCalibration == nil) {
                        if let currentCalibration {
                            onContinue(currentCalibration)
                        }
                    }
                }
                .hiddenWithChrome(isChromeHidden)
            }
        }
        .ignoresSafeArea(.keyboard)
        .task(id: scrubber.frameCount) {
            placeMarkersIfNeeded()
        }
    }

    /// The entered length written along the line, like a dimension on a drawing. Tapping it edits the length.
    private func lengthIndicator(from start: CGPoint, to end: CGPoint) -> some View {
        var angle = atan2(end.y - start.y, end.x - start.x)
        // Turned the short way round, so the text is never upside down.
        if angle > .pi / 2 { angle -= .pi }
        if angle < -.pi / 2 { angle += .pi }

        // Lifted off the line, on the side away from the screen's bottom, so it doesn't cover the reference.
        let lift: CGFloat = 24
        let center = CGPoint(x: (start.x + end.x) / 2 + sin(angle) * lift, y: (start.y + end.y) / 2 - cos(angle) * lift)

        // The glass is given an already-turned shape instead of being turned itself: rotating a glass
        // effect made it balloon into a lens on a real phone.
        return Text("\(lengthText.isEmpty ? "?" : lengthText) cm")
            .customFont(.caption, weight: .bold)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(.white)
            .frame(width: Self.indicatorSize.width - 14, height: Self.indicatorSize.height)
            .rotationEffect(.radians(angle))
            .frame(width: Self.indicatorSize.width, height: Self.indicatorSize.width)
            .glassEffect(.regular, in: TurnedCapsule(size: Self.indicatorSize, angle: .radians(angle)))
            .contentShape(TurnedCapsule(size: Self.indicatorSize, angle: .radians(angle)))
            .environment(\.colorScheme, .dark)
            .position(center)
            .onTapGesture {
                withAnimation(.smooth) { self.isChromeHidden = false }
                self.isLengthFieldFocused = true
            }
            .accessibilityLabel("Known length, \(lengthText) centimetres")
    }

    private static let indicatorSize = CGSize(width: 78, height: 26)

    private var lengthField: some View {
        HStack(spacing: 8) {
            Image(systemName: "ruler")
                .customFont(.subheadline, weight: .medium)
                .foregroundStyle(.secondary)

            TextField("100", text: $lengthText)
                .keyboardType(.decimalPad)
                // The decimal pad has no return key, so Done sits in a bar above it.
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()

                        Button("Done") {
                            Haptics.tap()
                            self.isLengthFieldFocused = false
                        }
                        .fontWeight(.semibold)
                    }
                }
                // Reached only from a hardware keyboard's return key.
                .onSubmit {
                    self.isLengthFieldFocused = false
                }
                .focused($isLengthFieldFocused)
                .multilineTextAlignment(.trailing)
                .customFont(.headline, weight: .bold)
                .frame(width: 64)
                .accessibilityLabel("Known length in centimetres")

            Text("cm")
                .customFont(.subheadline, weight: .medium)

            if isLengthFieldFocused {
                Button {
                    Haptics.tap()
                    self.isLengthFieldFocused = false
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .customFont(.title3, weight: .semibold)
                        .foregroundStyle(.tint)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Done")
            }
        }
        .padding(.horizontal, 14)
        .frame(height: GlassIconButton.height)
        .contentShape(.capsule)
        // The whole capsule opens the keyboard, not only the digits.
        .onTapGesture {
            self.isLengthFieldFocused = true
        }
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

/// A capsule of a fixed size, turned about the centre of whatever it is drawn in.
private struct TurnedCapsule: Shape {
    let size: CGSize
    let angle: Angle

    func path(in rect: CGRect) -> Path {
        let capsule = Path(roundedRect: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height), cornerRadius: size.height / 2)
        return capsule.applying(CGAffineTransform(rotationAngle: angle.radians)).applying(CGAffineTransform(translationX: rect.midX, y: rect.midY))
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
                    Haptics.tap()
                }
        )
        // Swallows taps on the marker, which would otherwise reach the video and hide the controls.
        .onTapGesture {}
        .accessibilityLabel("Marker")
    }
}
