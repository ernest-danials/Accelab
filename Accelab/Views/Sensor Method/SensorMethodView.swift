//
//  ContentView.swift
//  Accelab
//
//  Created by Myung Joon Kang on 2025-09-20.
//

import SwiftUI

struct SensorMethodView: View {
    @Environment(AngleManager.self) private var angleManager: AngleManager
    @Environment(MotionMeasuringManager.self) private var measuringManager: MotionMeasuringManager
    @Environment(\.scenePhase) private var scenePhase

    @State private var currentStep: SensorMethodStep = .idle

    @State private var currentDeviceOrientation: UIDeviceOrientation? = nil
    @State private var isShowingDeviceOrientationNotValidDisclaimer: Bool = false

    @AppStorage(AppStorageKey.marginOfErrorForAngle.rawValue) private var marginOfErrorForAngle: Double = 0.1
    @State private var desiredAngle: Double = ChooseAngleStepView.defaultAngle
    @State private var capturedAngle: Double? = nil

    @State private var csvURL: URL? = nil

    @State private var isShowingSettingsView: Bool = false
    @State private var isShowingWhatIsAccelabView: Bool = false

    var body: some View {
        ZStack {
            stepTitleView(for: currentStep)

            switch currentStep {
            case .idle:
                IdleStepView(onShowWhatIsAccelab: { self.isShowingWhatIsAccelabView = true }, onShowSettings: { self.isShowingSettingsView = true }, onStart: { changeCurrentStep(to: .chooseAngle) })
            case .chooseAngle:
                ChooseAngleStepView(desiredAngle: $desiredAngle, onCancel: { resetRun(); changeCurrentStep(to: .idle) }, onContinue: { changeCurrentStep(to: .determineAngle) })
            case .determineAngle:
                DetermineAngleStepView(desiredAngle: desiredAngle, marginOfErrorForAngle: marginOfErrorForAngle, currentDeviceOrientation: currentDeviceOrientation, isAngleReadyToCapture: isAngleReadyToCapture, isShowingDeviceOrientationNotValidDisclaimer: isShowingDeviceOrientationNotValidDisclaimer, onBack: {
                    self.capturedAngle = nil
                    changeCurrentStep(to: .chooseAngle)
                }, onContinue: { angle in
                    self.capturedAngle = angle
                    changeCurrentStep(to: .standby)
                })
            case .standby:
                StandbyStepView(currentDeviceOrientation: currentDeviceOrientation, onBegin: { changeCurrentStep(to: .countdown) }, onBack: { changeCurrentStep(to: .determineAngle) })
            case .countdown:
                CountdownStepView(onCancel: { changeCurrentStep(to: .standby) }, onFinished: startMeasuring)
            case .measuring:
                MeasuringStepView(splits: measuringManager.splits, onDiscard: discardMeasuring, onDone: finishMeasuring)
            case .completed:
                CompletedStepView(desiredAngle: desiredAngle, capturedAngle: capturedAngle, splits: measuringManager.splits, csvURL: csvURL, onRetryExport: exportCSV, onExit: { resetRun(); changeCurrentStep(to: .idle) })
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
                    discardMeasuring()
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
    private func stepTitleView(for step: SensorMethodStep) -> some View {
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

    private func changeCurrentStep(to step: SensorMethodStep) {
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

    // MARK: - Run lifecycle
    // The only places that talk to the measurement source.

    private func startMeasuring() {
        measuringManager.start()
        changeCurrentStep(to: .measuring)
    }

    private func finishMeasuring() {
        measuringManager.stop()
        changeCurrentStep(to: .completed)
        exportCSV()
    }

    /// Throws away the collected data but keeps the angle, so the run can be repeated.
    private func discardMeasuring() {
        measuringManager.reset()
        changeCurrentStep(to: .standby)
    }

    /// Clears everything belonging to the current run: collected data, angles, and exported files.
    private func resetRun() {
        measuringManager.reset()
        self.desiredAngle = ChooseAngleStepView.defaultAngle
        self.capturedAngle = nil
        CSVExporter.removeTempFiles()
        self.csvURL = nil
    }

    private func exportCSV() {
        self.csvURL = CSVExporter.writeTempFile(for: measuringManager.splits)
    }

    private var isAngleReadyToCapture: Bool {
        !isShowingDeviceOrientationNotValidDisclaimer && angleManager.isCurrentAngleWithinMargin(targetAngle: desiredAngle, margin: self.marginOfErrorForAngle)
    }
}

#Preview {
    SensorMethodView()
        .environment(AngleManager())
        .environment(MotionMeasuringManager())
}
