//
//  ContentView.swift
//  Accelab
//
//  Created by Myung Joon Kang on 2025-09-20.
//

import SwiftUI

struct ContentView: View {
    @Environment(AngleManager.self) private var angleManager: AngleManager
    @Environment(MeasuringManager.self) private var measuringManager: MeasuringManager
    @Environment(\.colorScheme) var colorScheme
    
    @State private var currentStep: Step = .idle
    
    @State private var currentDeviceOrientation: UIDeviceOrientation? = nil
    @State private var isShowingDeviceOrientationNotValidDisclaimer: Bool = false
    
    @AppStorage(AppStorageKey.marginOfErrorForAngle.rawValue) private var marginOfErrorForAngle: Double = 0.1
    @State private var desiredAngle: Double = 1.0
    @State private var capturedAngle: Double? = nil
    
    @State private var isShowingConfirmatoinDialogToGoBackInChooseAngleView: Bool = false
    @State private var isShowingConfirmationDialogToGoBackInMeasuringView: Bool = false
    @State private var isShowingConfirmationDialogToExitInCompletedView: Bool = false
    
    @State private var csvURL: URL? = nil
    
    @State private var isShowingSettingsView: Bool = false
    @State private var isShowingWhatIsAccelabView: Bool = false
    
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
                standbyView
            case .measuring:
                measuringView
            case .completed:
                completedView
            }
        }
        .background((angleManager.isCurrentAngleWithinMargin(targetAngle: desiredAngle, margin: self.marginOfErrorForAngle) && currentStep == .determineAngle) ? .green3.opacity(0.5) : .clear)
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
        .fullScreenCover(isPresented: $isShowingSettingsView) {
            SettingsView()
        }
        .fullScreenCover(isPresented: $isShowingWhatIsAccelabView) {
            WhatIsAccelabView()
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
            
            GlassButton(text: "What is Accelab?", style: .secondary) {
                self.isShowingWhatIsAccelabView = true
            }
            .alignView(to: .leading)
            .alignViewVertically(to: .bottom)
            .padding()
            
            HStack {
                GlassButton(text: "Settings", style: .secondary) {
                    self.isShowingSettingsView = true
                }
                
                GlassButton(text: "Start") {
                    changeCurrentStep(to: .chooseAngle)
                }
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
                    if self.desiredAngle == 1.0 {
                        changeCurrentStep(to: .idle)
                    } else {
                        self.isShowingConfirmatoinDialogToGoBackInChooseAngleView = true
                    }
                }
                .confirmationDialog("This will reset the angle you chose and take you back to the home screen. Are you sure?", isPresented: $isShowingConfirmatoinDialogToGoBackInChooseAngleView, titleVisibility: .visible) {
                    Button("Yes, reset and go back", role: .destructive) {
                        self.desiredAngle = 1.0
                        changeCurrentStep(to: .idle)
                    }
                }
                
                GlassButton(text: "Continue") {
                    angleManager.start()
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
                        .fill(angleManager.isCurrentAngleWithinMargin(targetAngle: desiredAngle, margin: self.marginOfErrorForAngle) ? (colorScheme == .dark ? .white : .black) : .accentColor)
                        .frame(width: 250, height: 4)
                }
            }
            .offset(y: 20)
            
            VStack(alignment: .leading) {
                Label("Target Angle: \(desiredAngle, specifier: "%.2f")°", systemImage: "angle")
                    .customFont(.subheadline, weight: .medium)
                
                Label("Margin of Error: \(self.marginOfErrorForAngle, specifier: "%.2f")°", systemImage: "plusminus")
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
                    angleManager.stop()
                    self.capturedAngle = nil
                    changeCurrentStep(to: .chooseAngle)
                }
                
                GlassButton(text: "Continue", isDisabled: !angleManager.isCurrentAngleWithinMargin(targetAngle: desiredAngle, margin: self.marginOfErrorForAngle)) {
                    angleManager.stop()
                    self.capturedAngle = angleManager.currentAngle
                    changeCurrentStep(to: .standby)
                }
            }
            .alignView(to: .trailing)
            .alignViewVertically(to: .bottom)
            .padding()
        }
    }
    
    @ViewBuilder
    private var standbyView: some View {
        ZStack {
            VStack {
                GlassButton(text: "Begin", textFont: .title) {
                    changeCurrentStep(to: .measuring)
                    measuringManager.start()
                }
                
                Text("Now that your track is all set, secure your iPhone to your cart and put in on the track. \nTap 'Begin' when you're ready to start recording.")
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
            
            GlassButton(text: "Back", style: .secondary) {
                angleManager.start()
                changeCurrentStep(to: .determineAngle)
            }
            .alignView(to: .trailing)
            .alignViewVertically(to: .bottom)
            .padding()
        }
    }
    
    @ViewBuilder
    private var measuringView: some View {
        ZStack {
            ScrollView(.horizontal) {
                LazyHStack {
                    ForEach(measuringManager.splits.reversed()) { split in
                        VStack(spacing: 15) {
                            Text("\(split.timeElapsed, specifier: "%.2f")")
                                .customFont(.title2, weight: .medium)
                            
                            Text("\(split.displacement, specifier: "%.2f")")
                                .customFont(.title2, weight: .medium)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .safeAreaPadding(.horizontal, 30)
            .safeAreaPadding(.leading, 100)
            
            if #available(iOS 26.0, *) {
                VStack(spacing: 15) {
                    VStack {
                        Image(systemName: "stopwatch.fill")
                            .customFont(.title3, weight: .medium)
                        
                        Text("Second")
                            .customFont(.footnote)
                    }
                    
                    VStack {
                        Image(systemName: "ruler.fill")
                            .customFont(.title3, weight: .medium)
                        
                        Text("Metre")
                            .customFont(.footnote)
                    }
                }
                .padding()
                .glassEffect()
                .alignView(to: .leading)
                .padding(30)
            } else {
                VStack(spacing: 15) {
                    VStack {
                        Image(systemName: "stopwatch.fill")
                            .customFont(.title3, weight: .medium)
                        
                        Text("Second")
                            .customFont(.footnote)
                    }
                    
                    VStack {
                        Image(systemName: "ruler.fill")
                            .customFont(.title3, weight: .medium)
                        
                        Text("Metre")
                            .customFont(.footnote)
                    }
                }
                .padding()
                .background(Material.ultraThin)
                .clipShape(.capsule)
                .alignView(to: .leading)
                .padding(30)
            }
            
            HStack {
                GlassButton(text: "Back", style: .secondary) {
                    self.isShowingConfirmationDialogToGoBackInMeasuringView = true
                }
                .confirmationDialog("This will reset all the collected data. Are you sure?", isPresented: $isShowingConfirmationDialogToGoBackInMeasuringView, titleVisibility: .visible) {
                    Button("Yes, reset and go back", role: .destructive) {
                        self.measuringManager.reset()
                        changeCurrentStep(to: .standby)
                    }
                }
                
                GlassButton(text: "Done", isDisabled: (measuringManager.splits.isEmpty)) {
                    measuringManager.stop()
                    changeCurrentStep(to: .completed)
                    self.csvURL = writeCSVTempFile(measuringManager.makeCSV())
                }
            }
            .alignView(to: .trailing)
            .alignViewVertically(to: .bottom)
            .padding()
        }
    }
    
    @ViewBuilder
    private var completedView: some View {
        ZStack {
            HStack(spacing: 15) {
                VStack {
                    Image(systemName: "angle")
                        .customFont(.title3, weight: .bold)
                        .padding(.bottom, 2)
                    
                    Text("Target Angle: \(desiredAngle, specifier: "%.2f")°")
                        .customFont(.title3, weight: .bold)
                    
                    if let capturedAngle = self.capturedAngle {
                        Text("Actual Angle: \(capturedAngle, specifier: "%.2f")°")
                            .customFont(.title3, weight: .bold)
                    } else {
                        Text("Actual Angle: Error")
                            .customFont(.title3, weight: .bold)
                    }
                    
                    Text("Margin: \(abs(desiredAngle - (capturedAngle ?? 0)), specifier: "%.2f")°")
                        .customFont(.footnote, weight: .medium)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                    .frame(height: 150)
                
                VStack {
                    Image(systemName: "tablecells")
                        .customFont(.title3, weight: .bold)
                        .padding(.bottom, 2)
                    
                    if let lastSplit = measuringManager.splits.last {
                        Text("Time Elapsed: \(lastSplit.timeElapsed, specifier: "%.2f") s")
                            .customFont(.title3, weight: .bold)
                        
                        Text("Distance Travelled: \(lastSplit.displacement, specifier: "%.2f") m")
                            .customFont(.title3, weight: .bold)
                    }
                    
                    Text("\(measuringManager.splits.count) Splits")
                        .customFont(.footnote, weight: .medium)
                        .foregroundStyle(.secondary)
                }
            }
            .offset(y: 15)
            
            HStack {
                if let url = csvURL {
                    if #available(iOS 26.0, *) {
                        ShareLink(item: url, preview: SharePreview("Accelab Data", icon: Image(systemName: "tablecells"))) {
                            Label("Export CSV", systemImage: "square.and.arrow.up")
                                .customFont(.title3, weight: .medium)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 20)
                        }
                        .buttonStyle(.glassProminent)
                    } else {
                        ShareLink(item: url, preview: SharePreview("Accelab Data", icon: Image(systemName: "tablecells"))) {
                            Label("Export CSV", systemImage: "square.and.arrow.up")
                                .customFont(.title3, weight: .medium)
                                .foregroundStyle(.white)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 25)
                                .background(.accent.gradient)
                                .cornerRadius(15, corners: .allCorners)
                        }
                    }
                } else {
                    ProgressView()
                }
                
                GlassButton(text: "Done", style: .secondary) {
                    self.isShowingConfirmationDialogToExitInCompletedView = true
                }
                .confirmationDialog("This will reset all your data and take you back to the home screen. Are you sure?", isPresented: $isShowingConfirmationDialogToExitInCompletedView, titleVisibility: .visible) {
                    Button("Yes, reset and go back", role: .destructive) {
                        self.measuringManager.reset()
                        self.desiredAngle = 1.0
                        self.capturedAngle = nil
                        changeCurrentStep(to: .idle)
                    }
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
    
    private func writeCSVTempFile(_ csv: String) -> URL? {
        let stamp = ISO8601DateFormatter().string(from: Date())
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("accelab-\(stamp).csv")
        
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
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
        .environment(MeasuringManager())
}
