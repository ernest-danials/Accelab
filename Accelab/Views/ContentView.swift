//
//  ContentView.swift
//  Accelab
//
//  Created by Myung Joon Kang on 2025-09-20.
//

import SwiftUI

struct ContentView: View {
    @Environment(AngleManager.self) var angleManager: AngleManager
    @Environment(\.colorScheme) var colorScheme
    
    @State private var currentStep: Step = .idle
    
    @State private var currentDeviceOrientation: UIDeviceOrientation? = nil
    @State private var isShowingDeviceOrientationNotValidDisclaimer: Bool = false
    
    @State private var desiredAngle: Double = 1.0
    
    var body: some View {
        ZStack {
            stepTitleView(for: currentStep)
            
            switch currentStep {
            case .idle:
                idleView
            case .chooseAngle:
                chooseAngleView
            case .determineAngle:
                determineAngleView.setUpForDeviceOrientationNotValidDisclaimer(isShowing: isShowingDeviceOrientationNotValidDisclaimer)
            case .standby:
                VStack {
                    
                }
            case .measuring:
                VStack {
                    
                }
            case .completed:
                VStack {
                    
                }
            }
        }
        .background((angleManager.isCurrentAngleWithinMargin(targetAngle: desiredAngle, margin: 0.1) && currentStep == .determineAngle) ? .green3.opacity(0.5) : .clear)
        .onChange(of: self.currentStep) { _, newValue in
            if newValue == .determineAngle {
                angleManager.start()
            } else {
                angleManager.stop()
            }
        }
        .onDeviceRotation { newOrientation in
            if newOrientation.isValidInterfaceOrientation {
                angleManager.start()
                withAnimation {
                    self.currentDeviceOrientation = newOrientation
                    self.isShowingDeviceOrientationNotValidDisclaimer = false
                }
            } else {
                angleManager.stop()
                withAnimation { self.isShowingDeviceOrientationNotValidDisclaimer = true }
            }
        }
    }
    
    @ViewBuilder
    private var idleView: some View {
        ZStack {
            VStack(spacing: 30) {
                Circle()
                    .frame(width: 90, height: 90)
                
                Capsule()
                    .frame(height: 5)
            }
            .foregroundStyle(.green2.gradient)
            .rotationEffect(.degrees(-20))
            
            GlassButton(text: "Start") {
                changeCurrentStep(to: .chooseAngle)
            }
            .alignView(to: .trailing)
            .alignViewVertically(to: .bottom)
            .padding()
        }
    }
    
    @ViewBuilder
    private var chooseAngleView: some View {
        ZStack {
            VStack {
                Slider(value: $desiredAngle, in: 1...50, step: 0.01) {
                    Text("Desired Angle")
                } minimumValueLabel: {
                    Text("1.00°")
                } maximumValueLabel: {
                    Text("50.00°")
                }
                .frame(width: 400)
                
                Text("\(desiredAngle, specifier: "%.2f")°")
                    .customFont(.largeTitle, weight: .bold)
                    .contentTransition(.numericText(value: desiredAngle))
                
                HStack {
                    let minAngle = 1.0
                    let maxAngle = 50.0

                    // –1°
                    GlassButton(text: "-1°", style: .secondary, textFont: .subheadline, isDisabled: (desiredAngle - 1.0) < minAngle) {
                        withAnimation {
                            desiredAngle = max(minAngle, desiredAngle - 1.0)
                            desiredAngle = (desiredAngle * 100).rounded() / 100
                        }
                    }

                    // +1°
                    GlassButton(text: "+1°", style: .secondary, textFont: .subheadline, isDisabled: (desiredAngle + 1.0) > maxAngle) {
                        withAnimation {
                            desiredAngle = min(maxAngle, desiredAngle + 1.0)
                            desiredAngle = (desiredAngle * 100).rounded() / 100
                        }
                    }

                    Divider()

                    // –0.1°
                    GlassButton(text: "-0.1°", style: .secondary, textFont: .subheadline, isDisabled: (desiredAngle - 0.1) < minAngle) {
                        withAnimation {
                            desiredAngle = max(minAngle, desiredAngle - 0.1)
                            desiredAngle = (desiredAngle * 100).rounded() / 100
                        }
                    }

                    // +0.1°
                    GlassButton(text: "+0.1°", style: .secondary, textFont: .subheadline, isDisabled: (desiredAngle + 0.1) > maxAngle) {
                        withAnimation {
                            desiredAngle = min(maxAngle, desiredAngle + 0.1)
                            desiredAngle = (desiredAngle * 100).rounded() / 100
                        }
                    }

                    Divider()

                    // –0.01°
                    GlassButton(text: "-0.01°", style: .secondary, textFont: .subheadline, isDisabled: (desiredAngle - 0.01) < minAngle) {
                        withAnimation {
                            desiredAngle = max(minAngle, desiredAngle - 0.01)
                            desiredAngle = (desiredAngle * 100).rounded() / 100
                        }
                    }

                    // +0.01°
                    GlassButton(text: "+0.01°", style: .secondary, textFont: .subheadline, isDisabled: (desiredAngle + 0.01) > maxAngle) {
                        withAnimation {
                            desiredAngle = min(maxAngle, desiredAngle + 0.01)
                            desiredAngle = (desiredAngle * 100).rounded() / 100
                        }
                    }
                }
                .frame(maxHeight: 50)
            }
            .offset(y: 15)
            
            HStack {
                GlassButton(text: "Cancel", style: .secondary) {
                    changeCurrentStep(to: .idle)
                    self.desiredAngle = 1.0
                }
                
                GlassButton(text: "Continue") {
                    changeCurrentStep(to: .determineAngle)
                }
            }
            .alignView(to: .trailing)
            .alignViewVertically(to: .bottom)
            .padding()
        }
    }
    
    @ViewBuilder
    private var determineAngleView: some View {
        ZStack {
            HStack {
                Text("\(angleManager.currentAngle, specifier: "%.2f")°")
                    .customFont(.largeTitle, weight: .bold)
                    .contentTransition(.numericText(value: angleManager.currentAngle))
                    .frame(width: 130)
                    .minimumScaleFactor(0.7)
                
                ZStack {
                    let isObtuse = angleManager.rawAngle > 90
                    let isLeft = (currentDeviceOrientation == .some(.landscapeLeft))
                    let anchor: UnitPoint = (isLeft != isObtuse) ? .leading : .trailing
                    let signedAngle = (anchor == .leading) ? angleManager.currentAngle : -angleManager.currentAngle

                    // Rotating ground (0° baseline relative to device)
                    Capsule()
                        .fill(Color.secondary)
                        .frame(width: 250, height: 4)
                        .rotationEffect(.degrees(signedAngle), anchor: anchor)
                        .animation(.easeInOut(duration: 0.15), value: angleManager.currentAngle)

                    // Fixed reference line (horizontal)
                    Capsule()
                        .fill(angleManager.isCurrentAngleWithinMargin(targetAngle: desiredAngle, margin: 0.1) ? (colorScheme == .dark ? .white : .black) : .accentColor)
                        .frame(width: 250, height: 4)
                }
            }
            .offset(y: 20)
            
            VStack(alignment: .leading) {
                Label("Target Angle: \(desiredAngle, specifier: "%.2f")°", systemImage: "angle")
                    .customFont(.subheadline, weight: .medium)
                
                #warning("Create an actual user preference manager for this")
                Label("Margin of Error: 0.10°", systemImage: "plusminus")
                    .customFont(.subheadline, weight: .medium)
                
                Text("You can change the margin of error in the settings menu.")
                    .customFont(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .alignView(to: .leading)
            .alignViewVertically(to: .bottom)
            
            HStack {
                GlassButton(text: "Back", style: .secondary) {
                    changeCurrentStep(to: .chooseAngle)
                }
                
                GlassButton(text: "Continue", isDisabled: !angleManager.isCurrentAngleWithinMargin(targetAngle: desiredAngle, margin: 0.1)) {
                    changeCurrentStep(to: .standby)
                }
            }
            .alignView(to: .trailing)
            .alignViewVertically(to: .bottom)
            .padding()
        }
    }
    
    @ViewBuilder
    private func stepTitleView(for step: Step) -> some View {
        VStack(alignment: .leading) {
            if !step.subtitle.isEmpty {
                Text(step.subtitle)
                    .customFont(step == .idle ? .title3 : .subheadline)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
        
            Text(step.title)
                .customFont(step == .idle ? .largeTitle : .title3, weight: .bold)
                .contentTransition(.numericText())
            
            if !step.description.isEmpty {
                Text(step.description)
                    .customFont(.footnote)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
        }
        .alignView(to: .leading)
        .alignViewVertically(to: .top)
        .padding(30)
    }
    
    private func changeCurrentStep(to step: Step) {
        withAnimation {
            self.currentStep = step
        }
    }
}

#warning("Refactor this")
enum Step: CaseIterable, Identifiable {
    case idle, chooseAngle, determineAngle, standby, measuring, completed
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .idle:
            return "Accelab"
        case .chooseAngle:
            return "Choose the Angle"
        case .determineAngle:
            return "Determine the Angle"
        case .standby:
            return ""
        case .measuring:
            return ""
        case .completed:
            return ""
        }
    }
    
    var subtitle: String {
        switch self {
        case .idle:
            return "Welcome to"
        case .chooseAngle:
            return "Step 1"
        case .determineAngle:
            return "Step 2"
        case .standby:
            return "Step 3"
        case .measuring:
            return "Step 4"
        case .completed:
            return ""
        }
    }
    
    var description: String {
        switch self {
        case .idle:
            return ""
        case .chooseAngle:
            return "Choose the desired slope of your track."
        case .determineAngle:
            return "Measure and determine the slope of your track."
        case .standby:
            return ""
        case .measuring:
            return ""
        case .completed:
            return ""
        }
    }
}

fileprivate extension View {
    func setUpForDeviceOrientationNotValidDisclaimer(isShowing: Bool) -> some View {
        self
            .overlay {
                if isShowing {
                    ContentUnavailableView("iPhone isn't upright", systemImage: "iphone.badge.exclamationmark", description: Text("Accelab can't measure the angle while your iPhone is lying flat. Hold it upright in landscape to continue."))
                        .frame(width: 350)
                        .alignView(to: .center)
                        .background(Material.ultraThin)
                }
            }
    }
}

#Preview {
    ContentView()
        .environment(AngleManager())
}
