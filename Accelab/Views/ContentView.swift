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
    @Environment(\.scenePhase) private var scenePhase

    @State private var currentStep: Step = .idle
    @State private var countdownValue: Int = 3
    
    @State private var currentDeviceOrientation: UIDeviceOrientation? = nil
    @State private var isShowingDeviceOrientationNotValidDisclaimer: Bool = false
    
    @AppStorage(AppStorageKey.marginOfErrorForAngle.rawValue) private var marginOfErrorForAngle: Double = 0.1
    @State private var desiredAngle: Double = 1.0
    @State private var capturedAngle: Double? = nil
    
    @State private var isShowingConfirmationDialogToGoBackInChooseAngleView: Bool = false
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
            case .countdown:
                countdownView
            case .measuring:
                measuringView
            case .completed:
                completedView
            }
        }
        // Check the step first so the body only observes `currentAngle` while determining the angle.
        .background((currentStep == .determineAngle && isAngleReadyToCapture) ? .green3.opacity(0.5) : .clear)
        .onDeviceRotation { newOrientation in
            withAnimation {
                if newOrientation.isValidInterfaceOrientation {
                    self.currentDeviceOrientation = newOrientation
                    self.isShowingDeviceOrientationNotValidDisclaimer = false
                } else {
                    self.isShowingDeviceOrientationNotValidDisclaimer = true
                }
            }
            updateAngleUpdates()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .background else { return }

            // The app is suspended in the background, so motion updates stop. End the run rather than
            // integrating across the gap when the app returns.
            switch currentStep {
            case .countdown:
                changeCurrentStep(to: .standby)
            case .measuring:
                if measuringManager.splits.isEmpty {
                    measuringManager.reset()
                    changeCurrentStep(to: .standby)
                } else {
                    finishMeasuring()
                }
            default:
                break
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
                        self.isShowingConfirmationDialogToGoBackInChooseAngleView = true
                    }
                }
                .confirmationDialog("This will reset the angle you chose and take you back to the home screen. Are you sure?", isPresented: $isShowingConfirmationDialogToGoBackInChooseAngleView, titleVisibility: .visible) {
                    Button("Yes, reset and go back", role: .destructive) {
                        self.desiredAngle = 1.0
                        changeCurrentStep(to: .idle)
                    }
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
                        .fill(isAngleReadyToCapture ? (colorScheme == .dark ? .white : .black) : .accentColor)
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
                    self.capturedAngle = nil
                    changeCurrentStep(to: .chooseAngle)
                }
                
                GlassButton(text: "Continue", isDisabled: !isAngleReadyToCapture) {
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
                    changeCurrentStep(to: .countdown)
                }
                
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
            
            GlassButton(text: "Back", style: .secondary) {
                changeCurrentStep(to: .determineAngle)
            }
            .alignView(to: .trailing)
            .alignViewVertically(to: .bottom)
            .padding()
        }
    }
    
    @ViewBuilder
    private var countdownView: some View {
        ZStack {
            Text("\(countdownValue)")
                .font(.system(size: 120, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: true))
                .offset(y: 15)
            
            GlassButton(text: "Cancel", style: .secondary) {
                changeCurrentStep(to: .standby)
            }
            .alignView(to: .trailing)
            .alignViewVertically(to: .bottom)
            .padding()
        }
        .task {
            // Cancelled automatically when the step changes and this view disappears.
            self.countdownValue = Self.countdownSeconds
            
            while self.countdownValue > 0 {
                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    return
                }
                
                withAnimation { self.countdownValue -= 1 }
            }
            
            measuringManager.start()
            changeCurrentStep(to: .measuring)
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
                    finishMeasuring()
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
                    ShareLink(item: url, preview: SharePreview("Accelab Data", icon: Image(systemName: "tablecells"))) {
                        Label("Export CSV", systemImage: "square.and.arrow.up")
                            .customFont(.title3, weight: .medium)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 20)
                    }
                    .buttonStyle(.glassProminent)
                } else {
                    // Only reachable if writing the temp file failed.
                    GlassButton(text: "Retry Export") {
                        self.csvURL = writeCSVTempFile(measuringManager.makeCSV())
                    }
                }
                
                GlassButton(text: "Done", style: .secondary) {
                    self.isShowingConfirmationDialogToExitInCompletedView = true
                }
                .confirmationDialog("This will reset all your data and take you back to the home screen. Are you sure?", isPresented: $isShowingConfirmationDialogToExitInCompletedView, titleVisibility: .visible) {
                    Button("Yes, reset and go back", role: .destructive) {
                        self.measuringManager.reset()
                        self.desiredAngle = 1.0
                        self.capturedAngle = nil
                        removeCSVTempFiles()
                        self.csvURL = nil
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
        
        updateAngleUpdates()
        
        // Keep the screen awake while the phone is on the track, where nobody touches it.
        UIApplication.shared.isIdleTimerDisabled = [.determineAngle, .standby, .countdown, .measuring].contains(step)
    }
    
    /// Runs angle updates only while determining the angle with the phone held upright.
    private func updateAngleUpdates() {
        if currentStep == .determineAngle && !isShowingDeviceOrientationNotValidDisclaimer {
            angleManager.start()
        } else {
            angleManager.stop()
        }
    }
    
    private func finishMeasuring() {
        measuringManager.stop()
        changeCurrentStep(to: .completed)
        self.csvURL = writeCSVTempFile(measuringManager.makeCSV())
    }
    
    private func writeCSVTempFile(_ csv: String) -> URL? {
        removeCSVTempFiles()
        
        // Avoid ':' (as in ISO 8601), which Finder shows as '/' and Windows rejects in file names.
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let stamp = formatter.string(from: Date())
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(Self.csvFilePrefix)\(stamp).csv")
        
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
    
    private func removeCSVTempFiles() {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: fileManager.temporaryDirectory, includingPropertiesForKeys: nil) else { return }
        
        for file in files where file.lastPathComponent.hasPrefix(Self.csvFilePrefix) && file.pathExtension == "csv" {
            try? fileManager.removeItem(at: file)
        }
    }
    
    private var isAngleReadyToCapture: Bool {
        !isShowingDeviceOrientationNotValidDisclaimer && angleManager.isCurrentAngleWithinMargin(targetAngle: desiredAngle, margin: self.marginOfErrorForAngle)
    }
    
    private static let countdownSeconds = 3
    private static let csvFilePrefix = "accelab-"
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
