//
//  CameraIdleStepView.swift
//  Accelab
//

import SwiftUI

struct CameraIdleStepView: View {
    /// What is going to be filmed. Chosen here, before the run starts, because it decides the steps.
    @Binding var experiment: CameraExperiment
    let onChangeMethod: () -> Void
    let onStart: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // The cart on its tilted track, drawn to the same measurements as the sensor method's idle screen.
    private static let slope: Angle = .degrees(-20)
    private static let cartSize: CGFloat = 90
    private static let trackSpacing: CGFloat = 30
    private static let trackThickness: CGFloat = 5

    // The projectile on the arc of its flight, drawn in the same manner.
    private static let arcSize = CGSize(width: 440, height: 120)
    private static let projectileSize: CGFloat = 70
    /// How far along the arc the projectile is, from 0 at the launch to 1 at the landing: just past the top.
    private static let projectileProgress: CGFloat = 0.6

    private static let cameraSize: CGFloat = 84
    private static let cameraCornerRadius: CGFloat = 24
    /// How far the camera sits from the middle of the cart, so that it overlaps the cart's edge
    /// without reaching the track.
    private static let cartCameraShift = CGSize(width: 46, height: 6)
    /// How far the camera sits from the middle of the projectile: below it, where it overlaps its edge
    /// and stays clear of the arc.
    private static let projectileCameraShift = CGSize(width: 8, height: 64)

    /// Slower than a button's, so that the track can be seen breaking up into the dots.
    private static let changeAnimation: Animation = .smooth(duration: 0.7)

    var body: some View {
        ZStack {
            // One line and one circle for both drawings, so choosing the other experiment turns one into
            // the other: the track breaks up into the dots of the flight, and the cart slides over to
            // become the projectile, as the camera slides with it.
            Group {
                TrackOrFlight(flight: experiment == .projectile ? 1 : 0, slope: Self.slope, trackCenterOffset: Self.trackCenterOffset, thickness: Self.trackThickness, arcSize: Self.arcSize)
                    .stroke(style: StrokeStyle(lineWidth: Self.trackThickness, lineCap: .round, lineJoin: .round))

                // Left plain: here the phone watches the cart instead of riding on it.
                Circle()
                    .frame(width: circleSize, height: circleSize)
                    .offset(circleOffset)
            }
            .foregroundStyle(Method.camera.color.gradient)

            // The camera, looking at what it films from beside it. Positioned rather than tilted along
            // with the track, because glass loses its shape when it is rotated.
            Image(systemName: Method.camera.imageName)
                .customFont(.largeTitle, weight: .medium)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.primary)
                .frame(width: Self.cameraSize, height: Self.cameraSize)
                .glassEffect(.regular, in: .rect(cornerRadius: Self.cameraCornerRadius))
                .offset(cameraOffset)

            GlassIconButton(systemImage: "chevron.backward", label: "Change Method", perform: onChangeMethod)
                .alignView(to: .leading)
                .alignViewVertically(to: .bottom)
                .padding()

            // In the row of the buttons, so choosing adds nothing to the screen's height. A segmented
            // control rather than two more buttons: it is one setting with two values.
            Picker("What to film", selection: $experiment.animation(reduceMotion ? nil : Self.changeAnimation)) {
                ForEach(CameraExperiment.allCases) { experiment in
                    Text(experiment.rawValue)
                        .tag(experiment)
                }
            }
            .pickerStyle(.segmented)
            .controlSize(.large)
            .frame(width: 260, height: GlassIconButton.height)
            .sensoryFeedback(.selection, trigger: experiment)
            .alignViewVertically(to: .bottom)
            .padding()

            GlassIconButton(systemImage: "play.fill", title: "Start", label: "Start", style: .prominent, perform: onStart)
                .alignView(to: .trailing)
                .alignViewVertically(to: .bottom)
                .padding()
        }
    }

    private var circleSize: CGFloat {
        experiment == .projectile ? Self.projectileSize : Self.cartSize
    }

    private var circleOffset: CGSize {
        experiment == .projectile ? Self.projectileOffset : Self.cartCenterOffset
    }

    private var cameraOffset: CGSize {
        switch experiment {
        case .airTrack:
            return CGSize(width: Self.cartCenterOffset.width + Self.cartCameraShift.width, height: Self.cartCenterOffset.height + Self.cartCameraShift.height)
        case .projectile:
            return CGSize(width: Self.projectileOffset.width + Self.projectileCameraShift.width, height: Self.projectileOffset.height + Self.projectileCameraShift.height)
        }
    }

    /// Where the cart's centre is, from the centre of the screen. The cart and the track are laid out as
    /// a stack (cart, gap, track) that is then tilted about its own centre.
    private static var cartCenterOffset: CGSize {
        // Before tilting, the cart's centre sits this far above the centre of the stack.
        let distance = (trackSpacing + trackThickness) / 2
        return CGSize(width: distance * sin(slope.radians), height: -distance * cos(slope.radians))
    }

    /// Where the middle of the track is, from the centre of the screen.
    private static var trackCenterOffset: CGSize {
        // Before tilting, the track's centre line sits this far below the centre of the stack.
        let distance = (cartSize + trackSpacing) / 2
        return CGSize(width: -distance * sin(slope.radians), height: distance * cos(slope.radians))
    }

    /// Where the projectile's centre is, from the centre of the screen.
    private static var projectileOffset: CGSize {
        CGSize(width: (projectileProgress - 0.5) * arcSize.width, height: (TrackOrFlight.arcHeight(at: projectileProgress) - 0.5) * arcSize.height)
    }
}

/// The line of the start screen's drawing: the tilted track at `flight` 0, the dotted arc of a projectile
/// at 1, and one turning into the other in between. The track is cut into as many pieces as the arc has
/// dots. Each piece shrinks to a dot, the ones at the launch first, while the whole line bends from the
/// track into the arc.
private struct TrackOrFlight: Shape {
    /// 0 for the track, 1 for the flight.
    var flight: CGFloat
    let slope: Angle
    /// The middle of the track, from the centre of the frame.
    let trackCenterOffset: CGSize
    /// How thick the line is stroked.
    let thickness: CGFloat
    /// The arc is launched from one bottom corner of a frame of this size, centred in the shape's own,
    /// is at its highest in the middle of the top edge, and lands in the other bottom corner.
    let arcSize: CGSize

    /// Dotted rather than solid: unlike a track, the flight's path isn't a thing in the shot. The dots are
    /// evenly spaced across the arc, not along it, like a projectile's positions at equal times.
    private static let dotCount = 29
    /// How much later the last piece starts to shrink than the first, as a share of the whole change.
    private static let splitStagger: CGFloat = 0.35
    /// How long each piece takes to shrink to a dot, as a share of the whole change.
    private static let splitDuration: CGFloat = 0.55
    /// A dot is drawn as a line this long, as a share of the whole line: a line of no length isn't drawn.
    private static let dotLength: CGFloat = 0.0002
    /// Each piece is drawn as this many straight lines, so that it follows the bend.
    private static let stepsPerPiece = 4

    var animatableData: CGFloat {
        get { flight }
        set { flight = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let flight = min(max(flight, 0), 1)
        let count = CGFloat(Self.dotCount)

        return Path { path in
            for index in 0..<Self.dotCount {
                let index = CGFloat(index)
                // The piece's middle, which moves from its place in the unbroken line to its dot's place:
                // the first and last dots sit on the very ends of the arc.
                let lineCenter = (index + 0.5) / count
                let dotCenter = index / (count - 1)
                let split = min(max((flight - Self.splitStagger * dotCenter) / Self.splitDuration, 0), 1)
                let center = lineCenter + (dotCenter - lineCenter) * split
                let length = max((1 - split) / count, Self.dotLength)

                for step in 0...Self.stepsPerPiece {
                    let progress = center + length * (CGFloat(step) / CGFloat(Self.stepsPerPiece) - 0.5)
                    let point = point(at: progress, flight: flight, in: rect)

                    if step == 0 {
                        path.move(to: point)
                    } else {
                        path.addLine(to: point)
                    }
                }
            }
        }
    }

    /// The point at `progress` along the line, from 0 at its left end to 1 at its right.
    private func point(at progress: CGFloat, flight: CGFloat, in rect: CGRect) -> CGPoint {
        // The track is as long as the frame is wide, like the sensor method's. Its round ends add half
        // its thickness each, so the line down its middle is shorter by that much.
        let trackLength = rect.width - thickness
        let along = (progress - 0.5) * trackLength
        let onTrack = CGPoint(x: trackCenterOffset.width + along * cos(slope.radians), y: trackCenterOffset.height + along * sin(slope.radians))
        let onArc = CGPoint(x: (progress - 0.5) * arcSize.width, y: (Self.arcHeight(at: progress) - 0.5) * arcSize.height)

        return CGPoint(x: rect.midX + onTrack.x + (onArc.x - onTrack.x) * flight, y: rect.midY + onTrack.y + (onArc.y - onTrack.y) * flight)
    }

    /// How far below the top of its frame the arc is at `progress` across it, as a share of the frame's
    /// height: a parabola through both bottom corners and the middle of the top edge.
    static func arcHeight(at progress: CGFloat) -> CGFloat {
        pow(1 - 2 * progress, 2)
    }
}
