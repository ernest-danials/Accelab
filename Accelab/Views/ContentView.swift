//
//  ContentView.swift
//  Accelab
//
//  Created by Myung Joon Kang on 2025-09-20.
//

import SwiftUI

struct ContentView: View {
    @Environment(AngleManager.self) var angleManager: AngleManager
    
    @State private var currentStep: Step = .idle
    @State private var currentDeviceOrientation: UIDeviceOrientation? = nil
    @State private var isShowingDeviceOrientationNotValidDisclaimer: Bool = false
    
    var body: some View {
        ZStack {
            switch currentStep {
            case .idle:
                idleView
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
            
            VStack(alignment: .leading) {
                Text(Step.idle.subtitle)
                    .customFont(.title2)
                    .foregroundStyle(.secondary)
                
                Text(Step.idle.title)
                    .customFont(.largeTitle, weight: .bold)
            }
            .alignView(to: .leading)
            .alignViewVertically(to: .top)
            .padding(30)
            
            if #available(iOS 26.0, *) {
                Button {
                    changeCurrentStep(to: .determineAngle)
                } label: {
                    Text("Continue")
                        .customFont(.title3, weight: .medium)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 20)
                }
                .buttonStyle(.glassProminent)
                .alignView(to: .trailing)
                .alignViewVertically(to: .bottom)
                .padding()
            } else {
                Button {
                    changeCurrentStep(to: .determineAngle)
                } label: {
                    Text("Continue")
                        .customFont(.title3, weight: .medium)
                        .foregroundStyle(.white)
                        .padding(.vertical, 9)
                        .padding(.horizontal, 25)
                        .background(.accent.gradient)
                        .cornerRadius(15, corners: .allCorners)
                }
                .scaleButtonStyle()
                .alignView(to: .trailing)
                .alignViewVertically(to: .bottom)
                .padding()
            }
        }
    }
    
    @ViewBuilder
    private var determineAngleView: some View {
        ZStack {
            VStack(alignment: .leading) {
                Text(Step.determineAngle.subtitle)
                    .customFont(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(Step.determineAngle.title)
                    .customFont(.title3, weight: .bold)
                
                Text(Step.determineAngle.description)
                    .customFont(.footnote)
                    .foregroundStyle(.secondary)
            }
            .alignView(to: .leading)
            .alignViewVertically(to: .top)
            .padding(30)
            
            HStack {
                Text("\(angleManager.currentAngle, specifier: "%.2f")°")
                    .customFont(.largeTitle, weight: .bold)
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
                        .fill(Color.accentColor)
                        .frame(width: 250, height: 4)
                }
            }
            .offset(y: 20)
        }
    }
    
    private func changeCurrentStep(to step: Step) {
        withAnimation {
            self.currentStep = step
        }
    }
}

enum Step: CaseIterable, Identifiable {
    case idle, determineAngle, standby, measuring, completed
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .idle:
            return "Accelab"
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
        case .determineAngle:
            return "Step 1"
        case .standby:
            return ""
        case .measuring:
            return ""
        case .completed:
            return ""
        }
    }
    
    var description: String {
        switch self {
        case .idle:
            return ""
        case .determineAngle:
            return "Measure or choose the slop of your track."
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
