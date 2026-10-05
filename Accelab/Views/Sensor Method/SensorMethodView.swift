//
//  SensorMethodView.swift
//  Accelab
//
//  Created by Myung Joon Kang on 2025-09-20.
//

import SwiftUI

struct SensorMethodView: View {
    @Environment(AngleManager.self) private var angleManager: AngleManager
    @Environment(MotionMeasuringManager.self) private var measuringManager: MotionMeasuringManager
    @Environment(MethodManager.self) private var methodManager: MethodManager
    @Environment(\.scenePhase) private var scenePhase

    @State private var currentStep: SensorMethodStep = .idle

    @State private var currentDeviceOrientation: UIDeviceOrientation? = nil

    @AppStorage(AppStorageKey.marginOfErrorForAngle.rawValue) private var marginOfErrorForAngle: Double = 0.1
    @State private var desiredAngle: Double = ChooseAngleStepView.defaultAngle
    @State private var capturedAngle: Double? = nil

    @State private var csvURL: URL? = nil

    var body: some View {
        ZStack {
            StepTitleView(title: currentStep.title, subtitle: currentStep.subtitle, description: currentStep.description, isProminent: currentStep == .idle)

            switch currentStep {
            case .idle:
                IdleStepView(onChangeMethod: { methodManager.changeMethod(to: nil) }, onStart: { changeCurrentStep(to: .chooseAngle) })
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
            guard newOrientation.isLandscape else { return }
            withAnimation { self.currentDeviceOrientation = newOrientation }
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
    }

    private func changeCurrentStep(to step: SensorMethodStep) {
        withAnimation {
            self.currentStep = step
        }

        updateAngleUpdates()

        // Keep the screen awake while the phone is on the track, where nobody touches it.
        UIApplication.shared.isIdleTimerDisabled = [.determineAngle, .standby, .countdown, .measuring].contains(step)
    }

    /// Runs angle updates only while determining the angle.
    private func updateAngleUpdates() {
        if currentStep == .determineAngle {
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

    /// The angle can't be read while the phone is lying flat.
    private var isShowingDeviceOrientationNotValidDisclaimer: Bool {
        angleManager.isFlat
    }

    private var isAngleReadyToCapture: Bool {
        !isShowingDeviceOrientationNotValidDisclaimer && angleManager.isCurrentAngleWithinMargin(targetAngle: desiredAngle, margin: self.marginOfErrorForAngle)
    }
}

#Preview {
    SensorMethodView()
        .environment(AngleManager())
        .environment(MotionMeasuringManager())
        .environment(MethodManager())
}
