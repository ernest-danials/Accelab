//
//  IdleStepView.swift
//  Accelab
//

import SwiftUI

struct IdleStepView: View {
    /// What is going to be measured. Chosen here, before the run starts, because it decides the steps.
    @Binding var experiment: SensorExperiment
    let onChangeMethod: () -> Void
    let onStart: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // The phone on its cart on the tilted track. The camera method's start screen draws its track to
    // these same measurements, so the two must stay equal.
    private static let slope: Angle = .degrees(-20)
    private static let cartSize: CGFloat = 90
    private static let trackSpacing: CGFloat = 30
    private static let trackThickness: CGFloat = 5

    // The phone on its turntable, seen from above: the turntable's rim, with the phone part-way out from
    // the middle, and the spindle at the centre.
    private static let turntableSize: CGFloat = 180
    private static let spindleSize: CGFloat = 8
    /// Smaller on the turntable than on the cart, as the projectile is on the camera's start screen, so
    /// that the spindle shows between it and the rim.
    private static let phoneOnTurntableSize: CGFloat = 70
    /// Where the middle of the turntable is, from the centre of the screen: a little below it, out from
    /// under the title.
    private static let turntableCenterOffset = CGSize(width: 0, height: 14)
    /// How far out from the middle of the turntable the phone sits.
    private static let phoneRadius: CGFloat = 48

    /// Slower than a button's, so that the track can be seen bending round into the turntable.
    private static let changeAnimation: Animation = .smooth(duration: 0.7)

    var body: some View {
        ZStack {
            // One line and one circle for both drawings, so choosing the other experiment turns one into
            // the other: the track bends round into the rim of the turntable while the phone slides onto it.
            // Drawn in a frame tilted with the track, as the cart's drawing always was: that keeps the
            // gradient running across the track's thickness, rather than down the screen, so the drawing
            // of the cart is the one there was before.
            ZStack {
                // Framed as tightly as the capsule the track used to be, so the gradient runs across its
                // thickness; the frame grows to the turntable's size along with the drawing.
                TrackOrTurntable(turntable: turntable, thickness: Self.trackThickness, turntableSize: Self.turntableSize, shift: Self.turntableShift)
                    .stroke(style: StrokeStyle(lineWidth: Self.trackThickness, lineCap: .round, lineJoin: .round))
                    .frame(height: Self.trackThickness + (Self.turntableSize - Self.trackThickness) * turntable)
                    .offset(CGSize(width: Self.trackCenter.width + Self.turntableShift.width * turntable, height: Self.trackCenter.height + Self.turntableShift.height * turntable))

                Circle()
                    .frame(width: Self.spindleSize, height: Self.spindleSize)
                    .offset(Self.turntableCenter)
                    .opacity(experiment == .circularMotion ? 1 : 0)

                Circle()
                    .frame(width: phoneSize, height: phoneSize)
                    .overlay {
                        // Counter-rotated so the icon stays upright on the tilted track.
                        Image(systemName: Method.sensor.imageName)
                            .customFont(.largeTitle, weight: .medium)
                            .foregroundStyle(.black.opacity(0.7))
                            .rotationEffect(-Self.slope)
                    }
                    .offset(phoneOffset)
            }
            .foregroundStyle(.green2.gradient)
            .rotationEffect(Self.slope)

            // The phone rides on the track and the cart either way round, and with Orientation Lock on the
            // screen can't turn to follow it. There is no way to read the setting, so this is always shown.
            // In the top corner, where it leaves the buttons' row to the choice of experiment.
            GlassStatusLabel {
                Label("Turn off Orientation Lock before you start", systemImage: "lock.rotation")
            }
            .alignView(to: .trailing)
            .alignViewVertically(to: .top)
            .padding()

            GlassIconButton(systemImage: "chevron.backward", label: "Change Method", perform: onChangeMethod)
                .alignView(to: .leading)
                .alignViewVertically(to: .bottom)
                .padding()

            // In the row of the buttons, so choosing adds nothing to the screen's height. A segmented
            // control rather than two more buttons: it is one setting with two values.
            Picker("What to measure", selection: $experiment.animation(reduceMotion ? nil : Self.changeAnimation)) {
                ForEach(SensorExperiment.allCases) { experiment in
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

    /// 0 for the track, 1 for the turntable.
    private var turntable: CGFloat {
        experiment == .circularMotion ? 1 : 0
    }

    private var phoneSize: CGFloat {
        experiment == .circularMotion ? Self.phoneOnTurntableSize : Self.cartSize
    }

    /// Where the phone's centre is, from the centre of the tilted frame.
    private var phoneOffset: CGSize {
        switch experiment {
        case .airTrack:
            return Self.cartCenter
        case .circularMotion:
            return Self.phoneOnTurntableCenter
        }
    }

    /// Where the cart's centre is, in the tilted frame. The cart and the track are laid out as a stack
    /// (cart, gap, track) centred in it, as they were when they were a `VStack`.
    private static var cartCenter: CGSize {
        CGSize(width: 0, height: -(trackSpacing + trackThickness) / 2)
    }

    /// Where the middle of the track is, in the tilted frame.
    private static var trackCenter: CGSize {
        CGSize(width: 0, height: (cartSize + trackSpacing) / 2)
    }

    /// Where the middle of the turntable is, in the tilted frame: `turntableCenterOffset` on the screen.
    private static var turntableCenter: CGSize {
        inTiltedFrame(turntableCenterOffset)
    }

    /// From the middle of the track to the middle of the turntable, in the tilted frame.
    private static var turntableShift: CGSize {
        CGSize(width: turntableCenter.width - trackCenter.width, height: turntableCenter.height - trackCenter.height)
    }

    /// Where the phone's centre is on the turntable, in the tilted frame: straight up from the
    /// turntable's middle on the screen.
    private static var phoneOnTurntableCenter: CGSize {
        inTiltedFrame(CGSize(width: turntableCenterOffset.width, height: turntableCenterOffset.height - phoneRadius))
    }

    /// An offset from the centre of the screen, as an offset in the frame tilted by `slope`, so that the
    /// tilt puts it back where it was meant to be.
    private static func inTiltedFrame(_ offset: CGSize) -> CGSize {
        let angle = -slope.radians
        return CGSize(width: offset.width * cos(angle) - offset.height * sin(angle), height: offset.width * sin(angle) + offset.height * cos(angle))
    }
}

/// The line of the start screen's drawing: the track at `turntable` 0, the rim of a turntable at 1, and
/// one bending into the other in between. The track's left end stays on the left while its right end
/// sweeps up, over the top, down the right and back along the bottom to meet it. Drawn in the frame
/// tilted with the track, so the track is a level line here.
///
/// Its frame is as thick as the track at 0 and as tall as the turntable at 1, moving from the one to the
/// other as it grows, so the drawing is placed from wherever the frame's middle currently is.
private struct TrackOrTurntable: Shape {
    /// 0 for the track, 1 for the turntable.
    var turntable: CGFloat
    /// How thick the line is stroked.
    let thickness: CGFloat
    /// The diameter of the turntable's rim.
    let turntableSize: CGFloat
    /// From the middle of the track to the middle of the turntable.
    let shift: CGSize

    /// How many straight lines the line is drawn as, so that it follows the bend.
    private static let steps = 120

    var animatableData: CGFloat {
        get { turntable }
        set { turntable = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let turntable = min(max(turntable, 0), 1)

        return Path { path in
            for step in 0...Self.steps {
                let point = point(at: CGFloat(step) / CGFloat(Self.steps), turntable: turntable, in: rect)

                if step == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }

            // The rim is a ring, with no seam where the line's ends meet.
            if turntable == 1 {
                path.closeSubpath()
            }
        }
    }

    /// The point at `progress` along the line, from 0 at the track's left end to 1 at its right.
    private func point(at progress: CGFloat, turntable: CGFloat, in rect: CGRect) -> CGPoint {
        // The track is as long as the frame is wide. Its round ends add half its thickness each, so the
        // line down its middle is shorter by that much.
        // The frame's middle is `turntable` of the way from the track's middle to the turntable's.
        let trackCenter = CGPoint(x: rect.midX - shift.width * turntable, y: rect.midY - shift.height * turntable)
        let rimCenter = CGPoint(x: trackCenter.x + shift.width, y: trackCenter.y + shift.height)

        let trackLength = rect.width - thickness
        let onTrack = CGPoint(x: trackCenter.x + (progress - 0.5) * trackLength, y: trackCenter.y)

        // Round the rim from its leftmost point, over the top and down the right, back along the bottom
        // (y runs downwards, so the angle increases clockwise).
        let angle = .pi + progress * 2 * .pi
        let radius = (turntableSize - thickness) / 2
        let onRim = CGPoint(x: rimCenter.x + radius * cos(angle), y: rimCenter.y + radius * sin(angle))

        return CGPoint(x: onTrack.x + (onRim.x - onTrack.x) * turntable, y: onTrack.y + (onRim.y - onTrack.y) * turntable)
    }
}
