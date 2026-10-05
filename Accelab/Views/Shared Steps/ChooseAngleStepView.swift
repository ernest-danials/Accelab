//
//  ChooseAngleStepView.swift
//  Accelab
//

import SwiftUI

struct ChooseAngleStepView: View {
    @Binding var desiredAngle: Double
    /// Called once the user has agreed to discard the chosen angle (or there was nothing to discard).
    let onCancel: () -> Void
    let onContinue: () -> Void
    /// Called once the user has agreed to carry on without an angle. `nil` hides the Skip button.
    var onSkip: (() -> Void)? = nil

    @State private var isShowingConfirmationDialogToGoBack: Bool = false
    @State private var isShowingConfirmationDialogToSkip: Bool = false

    static let angleRange: ClosedRange<Double> = 1.0...50.0
    static let defaultAngle: Double = angleRange.lowerBound

    var body: some View {
        ZStack {
            VStack {
                Slider(value: $desiredAngle, in: Self.angleRange, step: 0.01) {
                    Text("Desired Angle")
                } minimumValueLabel: {
                    Text("\(Self.angleRange.lowerBound, specifier: "%.2f")°")
                } maximumValueLabel: {
                    Text("\(Self.angleRange.upperBound, specifier: "%.2f")°")
                }
                .frame(width: 400)

                Text("\(desiredAngle, specifier: "%.2f")°")
                    .customFont(.largeTitle, weight: .bold)
                    .contentTransition(.numericText(value: desiredAngle))

                GlassEffectContainer {
                    HStack {
                        adjustButton("-1°", by: -1.0)
                        adjustButton("+1°", by: 1.0)

                        Divider()

                        adjustButton("-0.1°", by: -0.1)
                        adjustButton("+0.1°", by: 0.1)

                        Divider()

                        adjustButton("-0.01°", by: -0.01)
                        adjustButton("+0.01°", by: 0.01)
                    }
                    .frame(maxHeight: 50)
                }
            }
            .offset(y: 15)

            GlassEffectContainer {
                HStack {
                    GlassButton(text: "Cancel", style: .secondary) {
                        if self.desiredAngle == Self.defaultAngle {
                            onCancel()
                        } else {
                            self.isShowingConfirmationDialogToGoBack = true
                        }
                    }
                    .confirmationDialog("This will reset the angle you chose and take you back to the home screen. Are you sure?", isPresented: $isShowingConfirmationDialogToGoBack, titleVisibility: .visible) {
                        Button("Yes, reset and go back", role: .destructive, action: onCancel)
                    }

                    if let onSkip {
                        GlassButton(text: "Skip", style: .secondary) {
                            self.isShowingConfirmationDialogToSkip = true
                        }
                        .confirmationDialog("Without this step, Accelab won't help you set the slope of your track, and your results won't include an angle. Are you sure?", isPresented: $isShowingConfirmationDialogToSkip, titleVisibility: .visible) {
                            Button("Yes, skip the angle", action: onSkip)
                        }
                    }

                    GlassButton(text: "Continue", perform: onContinue)
                }
                .alignView(to: .trailing)
                .alignViewVertically(to: .bottom)
                .padding()
            }
        }
    }

    private func adjustButton(_ text: String, by delta: Double) -> some View {
        GlassButton(text: text, style: .secondary, textFont: .subheadline, isDisabled: !Self.angleRange.contains(desiredAngle + delta)) {
            withAnimation {
                let clamped = min(Self.angleRange.upperBound, max(Self.angleRange.lowerBound, desiredAngle + delta))
                desiredAngle = (clamped * 100).rounded() / 100
            }
        }
    }
}
