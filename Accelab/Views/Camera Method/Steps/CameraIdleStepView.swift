//
//  CameraIdleStepView.swift
//  Accelab
//

import SwiftUI

struct CameraIdleStepView: View {
    let onChangeMethod: () -> Void
    let onStart: () -> Void

    var body: some View {
        ZStack {
            Image(systemName: Method.camera.imageName)
                .customFont(.largeTitle, weight: .medium)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Method.camera.color)
                .frame(width: 90, height: 90)
                .glassEffect(.regular, in: .circle)

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
