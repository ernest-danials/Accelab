//
//  ProjectileIdleStepView.swift
//  Accelab
//

import SwiftUI

struct ProjectileIdleStepView: View {
    let onChangeMethod: () -> Void
    let onStart: () -> Void

    // The ball on the arc of its flight, drawn in the same manner as the cart on its track on the other
    // methods' idle screens.
    private static let arcSize = CGSize(width: 440, height: 120)
    private static let arcThickness: CGFloat = 5
    private static let ballSize: CGFloat = 70
    /// How far along the arc the ball is, from 0 at the launch to 1 at the landing: just past the top.
    private static let ballProgress: CGFloat = 0.6
    private static let cameraSize: CGFloat = 84
    private static let cameraCornerRadius: CGFloat = 24
    /// How far the camera sits from the middle of the ball: below it, where it overlaps the ball's edge
    /// and stays clear of the arc.
    private static let cameraShift = CGSize(width: 8, height: 64)

    var body: some View {
        ZStack {
            ZStack {
                // Dotted rather than solid: unlike a track, the flight's path isn't a thing in the shot.
                FlightArc()
                    .stroke(style: StrokeStyle(lineWidth: Self.arcThickness, lineCap: .round, dash: [0.1, 16]))
                    .frame(width: Self.arcSize.width, height: Self.arcSize.height)

                Circle()
                    .frame(width: Self.ballSize, height: Self.ballSize)
                    .offset(Self.ballOffset)
            }
            .foregroundStyle(Method.projectile.color.gradient)

            // The camera, looking at the ball from beside the flight.
            Image(systemName: Method.camera.imageName)
                .customFont(.largeTitle, weight: .medium)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.primary)
                .frame(width: Self.cameraSize, height: Self.cameraSize)
                .glassEffect(.regular, in: .rect(cornerRadius: Self.cameraCornerRadius))
                .offset(x: Self.ballOffset.width + Self.cameraShift.width, y: Self.ballOffset.height + Self.cameraShift.height)

            GlassIconButton(systemImage: "chevron.backward", label: "Change Method", perform: onChangeMethod)
                .alignView(to: .leading)
                .alignViewVertically(to: .bottom)
                .padding()

            GlassIconButton(systemImage: "play.fill", title: "Start", label: "Start", style: .prominent, perform: onStart)
                .alignView(to: .trailing)
                .alignViewVertically(to: .bottom)
                .padding()
        }
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

#Preview(traits: .landscapeLeft) {
    ProjectileIdleStepView(onChangeMethod: {}, onStart: {})
}
