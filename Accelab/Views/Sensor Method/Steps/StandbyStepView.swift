//
//  StandbyStepView.swift
//  Accelab
//

import SwiftUI

struct StandbyStepView: View {
    let experiment: SensorExperiment
    let currentDeviceOrientation: UIDeviceOrientation?
    let onBegin: () -> Void
    let onBack: () -> Void

    var body: some View {
        ZStack {
            VStack {
                GlassButton(text: "Begin", textFont: .title, perform: onBegin)

                Text(instructions)
                    .customFont(.footnote, weight: .medium)
                    .multilineTextAlignment(.center)
                    .frame(width: 300)
            }
            .offset(y: 15)

            // The phone's top edge is on one side of the screen or the other, and what it must point at
            // depends on the experiment.
            HStack {
                if currentDeviceOrientation == .landscapeLeft {
                    Image(systemName: "chevron.compact.left")
                        .font(.system(size: 60))
                        .transition(.blurReplace)
                }

                Text(directionText)
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

            Label(warning, systemImage: "exclamationmark.triangle.fill")
                .customFont(.footnote, weight: .medium)
                .foregroundStyle(.red)
                .multilineTextAlignment(.leading)
                .frame(width: 300)
                .minimumScaleFactor(0.7)
                .padding()
                .alignView(to: .leading)
                .alignViewVertically(to: .bottom)

            GlassIconButton(systemImage: "chevron.backward", label: "Back", perform: onBack)
                .alignView(to: .trailing)
                .alignViewVertically(to: .bottom)
                .padding()
        }
    }

    private var instructions: String {
        switch experiment {
        case .airTrack:
            return "Now that your track is all set, secure your iPhone to your cart and put it on the track. \nTap 'Begin' when you're ready to start recording."
        case .circularMotion:
            return "Lay your iPhone flat on the turntable, with its top edge pointing at the centre, and fasten it. \nTap 'Begin' when you're ready to start recording."
        }
    }

    private var directionText: String {
        switch experiment {
        case .airTrack:
            return "Your cart must be facing this way"
        case .circularMotion:
            return "The centre of the turntable must be this way"
        }
    }

    private var warning: String {
        switch experiment {
        case .airTrack:
            return "Make sure your iPhone is securely fastened on the cart. Otherwise, your iPhone may fall off and get damaged."
        case .circularMotion:
            return "Make sure your iPhone is securely fastened to the turntable. A spinning turntable can throw it off and damage it."
        }
    }
}
