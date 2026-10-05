//
//  IdleStepView.swift
//  Accelab
//

import SwiftUI

struct IdleStepView: View {
    let onChangeMethod: () -> Void
    let onStart: () -> Void

    var body: some View {
        ZStack {
            VStack(spacing: 30) {
                Circle()
                    .frame(width: 90, height: 90)
                    .overlay {
                        // Counter-rotated so the icon stays upright on the tilted track.
                        Image(systemName: Method.sensor.imageName)
                            .customFont(.largeTitle, weight: .medium)
                            .foregroundStyle(.black.opacity(0.7))
                            .rotationEffect(.degrees(20))
                    }

                Capsule()
                    .frame(height: 5)
            }
            .foregroundStyle(.green2.gradient)
            .rotationEffect(.degrees(-20))

            GlassButton(text: "Change Method", style: .secondary, perform: onChangeMethod)
                .alignView(to: .leading)
                .alignViewVertically(to: .bottom)
                .padding()

            GlassButton(text: "Start", perform: onStart)
                .alignView(to: .trailing)
                .alignViewVertically(to: .bottom)
                .padding()
        }
    }
}
