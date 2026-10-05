//
//  CameraIdleStepView.swift
//  Accelab
//

import SwiftUI

struct CameraIdleStepView: View {
    let onChangeMethod: () -> Void
    let onStart: () -> Void

    // The cart on its tilted track, drawn to the same measurements as the sensor method's idle screen.
    private static let slope: Angle = .degrees(-20)
    private static let cartSize: CGFloat = 90
    private static let trackSpacing: CGFloat = 30
    private static let trackThickness: CGFloat = 5
    private static let cameraSize: CGFloat = 72
    private static let cameraCornerRadius: CGFloat = 20
    /// How far the camera sits from the middle of the cart, so that it overlaps the cart's edge
    /// without reaching the track.
    private static let cameraShift = CGSize(width: 40, height: 14)

    var body: some View {
        ZStack {
            VStack(spacing: Self.trackSpacing) {
                // Left plain: here the phone watches the cart instead of riding on it.
                Circle()
                    .frame(width: Self.cartSize, height: Self.cartSize)

                Capsule()
                    .frame(height: Self.trackThickness)
            }
            .foregroundStyle(Method.camera.color.gradient)
            .rotationEffect(Self.slope)

            // The camera, looking at the cart from beside it. Positioned here rather than tilted along
            // with the drawing, because glass loses its shape when it is rotated.
            Image(systemName: Method.camera.imageName)
                .customFont(.largeTitle, weight: .medium)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.primary)
                .frame(width: Self.cameraSize, height: Self.cameraSize)
                .glassEffect(.regular, in: .rect(cornerRadius: Self.cameraCornerRadius))
                .offset(x: Self.cartCenterOffset.width + Self.cameraShift.width, y: Self.cartCenterOffset.height + Self.cameraShift.height)

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

    /// Where the cart's centre ends up once the drawing has been tilted about its own centre.
    private static var cartCenterOffset: CGSize {
        // Before tilting, the cart's centre sits this far above the centre of the cart-and-track drawing.
        let distance = (trackSpacing + trackThickness) / 2
        return CGSize(width: distance * sin(slope.radians), height: -distance * cos(slope.radians))
    }
}
