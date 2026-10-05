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
    private static let lensSize: CGFloat = 66

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

            // The camera, looking at the cart. Placed over the cart rather than tilted along with it,
            // because glass loses its shape when it is rotated.
            Image(systemName: Method.camera.imageName)
                .customFont(.title, weight: .medium)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.white)
                .frame(width: Self.lensSize, height: Self.lensSize)
                .glassEffect(.clear, in: .circle)
                .offset(Self.cartCenterOffset)

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
