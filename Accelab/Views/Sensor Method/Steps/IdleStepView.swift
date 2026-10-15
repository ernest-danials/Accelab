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

            // The phone rides on the track and the cart either way round, and with Orientation Lock on the
            // screen can't turn to follow it. There is no way to read the setting, so this is always shown.
            GlassStatusLabel {
                Label("Turn off Orientation Lock before you start", systemImage: "lock.rotation")
            }
            .alignViewVertically(to: .bottom)
            .padding()

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
}
