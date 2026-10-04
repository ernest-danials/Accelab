//
//  StandbyStepView.swift
//  Accelab
//

import SwiftUI

struct StandbyStepView: View {
    let currentDeviceOrientation: UIDeviceOrientation?
    let onBegin: () -> Void
    let onBack: () -> Void

    var body: some View {
        ZStack {
            VStack {
                GlassButton(text: "Begin", textFont: .title, perform: onBegin)

                Text("Now that your track is all set, secure your iPhone to your cart and put it on the track. \nTap 'Begin' when you're ready to start recording.")
                    .customFont(.footnote, weight: .medium)
                    .multilineTextAlignment(.center)
                    .frame(width: 300)
            }
            .offset(y: 15)

            HStack {
                if currentDeviceOrientation == .landscapeLeft {
                    Image(systemName: "chevron.compact.left")
                        .font(.system(size: 60))
                        .transition(.blurReplace)
                }

                Text("Your cart must be facing this way")
                    .customFont(.subheadline, weight: .medium)

                if currentDeviceOrientation == .landscapeRight {
                    Image(systemName: "chevron.compact.right")
                        .font(.system(size: 60))
                        .transition(.blurReplace)
                }
            }
            .foregroundStyle(.yellow)
            .frame(width: 120)
            .alignView(to: currentDeviceOrientation == .landscapeLeft ? .leading : .trailing)
            .padding()

            Label("Make sure your iPhone is securely fastened on the cart. Otherwise, your iPhone may fall off and get damaged.", systemImage: "exclamationmark.triangle.fill")
                .customFont(.footnote, weight: .medium)
                .foregroundStyle(.red)
                .multilineTextAlignment(.leading)
                .frame(width: 300)
                .minimumScaleFactor(0.7)
                .padding()
                .alignView(to: .leading)
                .alignViewVertically(to: .bottom)

            GlassButton(text: "Back", style: .secondary, perform: onBack)
                .alignView(to: .trailing)
                .alignViewVertically(to: .bottom)
                .padding()
        }
    }
}
