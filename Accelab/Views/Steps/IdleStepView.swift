//
//  IdleStepView.swift
//  Accelab
//

import SwiftUI

struct IdleStepView: View {
    let onShowWhatIsAccelab: () -> Void
    let onShowSettings: () -> Void
    let onStart: () -> Void

    var body: some View {
        ZStack {
            VStack(spacing: 30) {
                Circle()
                    .frame(width: 90, height: 90)

                Capsule()
                    .frame(height: 5)
            }
            .foregroundStyle(.green2.gradient)
            .rotationEffect(.degrees(-20))

            GlassButton(text: "What is Accelab?", style: .secondary, perform: onShowWhatIsAccelab)
                .alignView(to: .leading)
                .alignViewVertically(to: .bottom)
                .padding()

            HStack {
                GlassButton(text: "Settings", style: .secondary, perform: onShowSettings)

                GlassButton(text: "Start", perform: onStart)
            }
            .alignView(to: .trailing)
            .alignViewVertically(to: .bottom)
            .padding()
        }
    }
}
