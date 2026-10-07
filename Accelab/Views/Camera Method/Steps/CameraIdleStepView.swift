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

    // The cart on its tilted track, drawn to the same measurements as the sensor method's idle screen.
    private static let slope: Angle = .degrees(-20)
    private static let cartSize: CGFloat = 90
    private static let trackSpacing: CGFloat = 30
    private static let trackThickness: CGFloat = 5

    // The ball on the arc of its flight, drawn in the same manner.
    private static let arcSize = CGSize(width: 440, height: 120)
    private static let ballSize: CGFloat = 70
    /// How far along the arc the ball is, from 0 at the launch to 1 at the landing: just past the top.
    private static let ballProgress: CGFloat = 0.6

    private static let cameraSize: CGFloat = 84
    private static let cameraCornerRadius: CGFloat = 24
    /// How far the camera sits from the middle of the cart, so that it overlaps the cart's edge
    /// without reaching the track.
    private static let cartCameraShift = CGSize(width: 46, height: 6)
    /// How far the camera sits from the middle of the ball: below it, where it overlaps the ball's edge
    /// and stays clear of the arc.
    private static let ballCameraShift = CGSize(width: 8, height: 64)

    var body: some View {
        ZStack {
            Group {
                switch experiment {
                case .airTrack:
                    VStack(spacing: Self.trackSpacing) {
                        // Left plain: here the phone watches the cart instead of riding on it.
                        Circle()
                            .frame(width: Self.cartSize, height: Self.cartSize)

                        Capsule()
                            .frame(height: Self.trackThickness)
                    }
                    .rotationEffect(Self.slope)
                    .transition(.opacity)
                case .projectile:
                    ZStack {
                        // Dotted rather than solid: unlike a track, the flight's path isn't a thing in the shot.
                        FlightArc()
                            .stroke(style: StrokeStyle(lineWidth: Self.trackThickness, lineCap: .round, dash: [0.1, 16]))
                            .frame(width: Self.arcSize.width, height: Self.arcSize.height)

                        Circle()
                            .frame(width: Self.ballSize, height: Self.ballSize)
                            .offset(Self.ballOffset)
                    }
                    .transition(.opacity)
                }
            }
            .foregroundStyle(Method.camera.color.gradient)

            // The camera, looking at what it films from beside it. One tile for both drawings, so it slides
            // from one to the other; positioned rather than tilted along with the drawing, because glass
            // loses its shape when it is rotated.
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
            Picker("What to film", selection: $experiment.animation(.smooth)) {
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

    private var cameraOffset: CGSize {
        switch experiment {
        case .airTrack:
            return CGSize(width: Self.cartCenterOffset.width + Self.cartCameraShift.width, height: Self.cartCenterOffset.height + Self.cartCameraShift.height)
        case .projectile:
            return CGSize(width: Self.ballOffset.width + Self.ballCameraShift.width, height: Self.ballOffset.height + Self.ballCameraShift.height)
        }
    }

    /// Where the cart's centre ends up once the drawing has been tilted about its own centre.
    private static var cartCenterOffset: CGSize {
        // Before tilting, the cart's centre sits this far above the centre of the cart-and-track drawing.
        let distance = (trackSpacing + trackThickness) / 2
        return CGSize(width: distance * sin(slope.radians), height: -distance * cos(slope.radians))
    }

    /// Where the ball's centre is, from the centre of the arc's frame.
    private static var ballOffset: CGSize {
        CGSize(width: (ballProgress - 0.5) * arcSize.width, height: FlightArc.height(at: ballProgress) * arcSize.height - arcSize.height / 2)
    }
}

/// The path of a projectile across the frame it is drawn in: launched from one bottom corner, at its
/// highest in the middle of the top edge, and landing in the other bottom corner.
private struct FlightArc: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            // A quadratic curve is a parabola. With its control point as far above the top edge as the
            // ends are below it, the curve just touches that edge.
            path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.midX, y: rect.minY - rect.height))
        }
    }

    /// How far below the top of the frame the arc is at `progress` along its width, as a fraction of the frame's height.
    static func height(at progress: CGFloat) -> CGFloat {
        pow(1 - 2 * progress, 2)
    }
}
