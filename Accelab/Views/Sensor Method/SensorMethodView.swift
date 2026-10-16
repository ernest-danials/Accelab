//
//  SensorMethodView.swift
//  Accelab
//
//  Created by Myung Joon Kang on 2025-09-20.
//

import SwiftUI
import SwiftData

struct SensorMethodView: View {
    @Environment(AngleManager.self) private var angleManager: AngleManager
    @Environment(MotionMeasuringManager.self) private var measuringManager: MotionMeasuringManager
    @Environment(RotationMeasuringManager.self) private var rotationManager: RotationMeasuringManager
    @Environment(MethodManager.self) private var methodManager: MethodManager
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

    @State private var currentStep: SensorMethodStep = .idle
    /// What is being measured. Chosen on the start screen and kept across runs.
    @State private var experiment: SensorExperiment = .airTrack

    @State private var currentDeviceOrientation: UIDeviceOrientation? = nil

    @AppStorage(AppStorageKey.marginOfErrorForAngle.rawValue) private var marginOfErrorForAngle: Double = 0.1
    @State private var desiredAngle: Double = ChooseAngleStepView.defaultAngle
    @State private var capturedAngle: Double? = nil
    @State private var isAngleSkipped: Bool = false

    @State private var csvURL: URL? = nil
    @State private var desmosURL: URL? = nil
    /// The current run in the past runs, once it has finished.
    @State private var savedRun: SavedRun? = nil

    var body: some View {
        ZStack {
            StepTitleView(title: currentStep.title(for: experiment), subtitle: currentStep.subtitle(for: experiment), description: currentStep.description(for: experiment), isProminent: currentStep == .idle)

            switch currentStep {
            case .idle:
                IdleStepView(experiment: $experiment, onChangeMethod: { methodManager.changeMethod(to: nil) }, onStart: { changeCurrentStep(to: experiment.measuresAngle ? .chooseAngle : .standby) })
            case .chooseAngle:
                ChooseAngleStepView(desiredAngle: $desiredAngle, onCancel: { resetRun(); changeCurrentStep(to: .idle) }, onContinue: {
                    self.isAngleSkipped = false
                    changeCurrentStep(to: .determineAngle)
                }, onSkip: {
                    self.isAngleSkipped = true
                    self.capturedAngle = nil
                    changeCurrentStep(to: .standby)
                })
            case .determineAngle:
                DetermineAngleStepView(desiredAngle: desiredAngle, marginOfErrorForAngle: marginOfErrorForAngle, currentDeviceOrientation: currentDeviceOrientation, isAngleReadyToCapture: isAngleReadyToCapture, isShowingDeviceOrientationNotValidDisclaimer: isShowingDeviceOrientationNotValidDisclaimer, onBack: {
                    self.capturedAngle = nil
                    changeCurrentStep(to: .chooseAngle)
                }, onContinue: { angle in
                    self.capturedAngle = angle
                    changeCurrentStep(to: .standby)
                })
            case .standby:
                StandbyStepView(experiment: experiment, currentDeviceOrientation: currentDeviceOrientation, onBegin: startCountdown, onBack: {
                    if !experiment.measuresAngle {
                        resetRun()
                        changeCurrentStep(to: .idle)
                    } else {
                        changeCurrentStep(to: isAngleSkipped ? .chooseAngle : .determineAngle)
                    }
                })
            case .countdown:
                CountdownStepView(onCancel: cancelCountdown, onFinished: startMeasuring)
            case .measuring:
                MeasuringStepView(data: currentData, onDiscard: discardMeasuring, onDone: finishMeasuring)
            case .completed:
                CompletedStepView(desiredAngle: summaryDesiredAngle, capturedAngle: capturedAngle, data: currentData, csvURL: csvURL, desmosURL: desmosURL, onRetryExport: exportCSV, onExit: { resetRun(); changeCurrentStep(to: .idle) })
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
                cancelCountdown()
            case .measuring:
                if currentData.isEmpty {
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
    // The only places that talk to the measurement sources.

    /// The samples of the run so far, from whichever manager measures this experiment.
    private var currentData: RunData {
        switch experiment {
        case .airTrack:
            return .distance(measuringManager.splits)
        case .circularMotion:
            return .rotation(rotationManager.splits)
        }
    }

    /// The angle the summary shows. `nil` when the angle steps were skipped, and for a turntable, which has none.
    private var summaryDesiredAngle: Double? {
        experiment.measuresAngle && !isAngleSkipped ? desiredAngle : nil
    }

    /// For a turntable the sensors are read through the countdown, while it still stands, to learn what
    /// the accelerometer says at rest.
    private func startCountdown() {
        if experiment == .circularMotion {
            rotationManager.start()
        }
        changeCurrentStep(to: .countdown)
    }

    private func cancelCountdown() {
        rotationManager.reset()
        changeCurrentStep(to: .standby)
    }

    private func startMeasuring() {
        switch experiment {
        case .airTrack:
            measuringManager.start()
        case .circularMotion:
            rotationManager.beginRecording()
        }
        changeCurrentStep(to: .measuring)
    }

    private func finishMeasuring() {
        measuringManager.stop()
        rotationManager.stop()
        changeCurrentStep(to: .completed)
        exportCSV()
        saveRun()
    }

    /// Keeps the finished run in the past runs. It stays there after `resetRun()`.
    private func saveRun() {
        let data = currentData
        guard !data.isEmpty else { return }

        if let savedRun {
            savedRun.update(data: data)
        } else {
            let run = SavedRun(method: .sensor, sensorExperiment: experiment, desiredAngle: summaryDesiredAngle, capturedAngle: capturedAngle, data: data)
            modelContext.insert(run)
            self.savedRun = run
        }
    }

    /// Throws away the collected data but keeps the angle, so the run can be repeated.
    private func discardMeasuring() {
        measuringManager.reset()
        rotationManager.reset()
        changeCurrentStep(to: .standby)
    }

    /// Clears everything belonging to the current run: collected data, angles, and exported files.
    private func resetRun() {
        measuringManager.reset()
        rotationManager.reset()
        self.savedRun = nil
        self.desiredAngle = ChooseAngleStepView.defaultAngle
        self.capturedAngle = nil
        self.isAngleSkipped = false
        CSVExporter.removeTempFiles()
        self.csvURL = nil
        self.desmosURL = nil
    }

    private func exportCSV() {
        let data = currentData
        self.csvURL = CSVExporter.writeTempFile(for: data)
        self.desmosURL = CSVExporter.writeDesmosTempFile(for: data)
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
        .environment(RotationMeasuringManager())
        .environment(MethodManager())
        .modelContainer(for: SavedRun.self, inMemory: true)
}
