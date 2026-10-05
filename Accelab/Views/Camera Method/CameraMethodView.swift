//
//  CameraMethodView.swift
//  Accelab
//
//  Created by Myung Joon Kang on 2026-10-04.
//

import SwiftUI

struct CameraMethodView: View {
    @Environment(AngleManager.self) private var angleManager: AngleManager
    @Environment(CameraCaptureManager.self) private var captureManager: CameraCaptureManager
    @Environment(MethodManager.self) private var methodManager: MethodManager
    @Environment(\.scenePhase) private var scenePhase

    @State private var currentStep: CameraMethodStep = .idle

    @State private var currentDeviceOrientation: UIDeviceOrientation? = nil

    @AppStorage(AppStorageKey.marginOfErrorForAngle.rawValue) private var marginOfErrorForAngle: Double = 0.1
    @State private var desiredAngle: Double = ChooseAngleStepView.defaultAngle
    @State private var capturedAngle: Double? = nil
    @State private var isAngleSkipped: Bool = false

    @State private var scrubber: VideoScrubber? = nil
    @State private var calibration: CameraCalibration? = nil
    @State private var trackedPoints: [TrackedPoint] = []

    @State private var splits: [DistanceSplit] = []
    @State private var csvURL: URL? = nil

    var body: some View {
        ZStack {
            StepTitleView(title: currentStep.title, subtitle: currentStep.subtitle, description: currentStep.description, isProminent: currentStep == .idle, isCompact: [.record, .calibrate, .track].contains(currentStep))

            switch currentStep {
            case .idle:
                CameraIdleStepView(onChangeMethod: { methodManager.changeMethod(to: nil) }, onStart: { changeCurrentStep(to: .chooseAngle) })
            case .chooseAngle:
                ChooseAngleStepView(desiredAngle: $desiredAngle, onCancel: { resetRun(); changeCurrentStep(to: .idle) }, onContinue: {
                    self.isAngleSkipped = false
                    changeCurrentStep(to: .determineAngle)
                }, onSkip: {
                    self.isAngleSkipped = true
                    self.capturedAngle = nil
                    changeCurrentStep(to: .setup)
                })
            case .determineAngle:
                DetermineAngleStepView(desiredAngle: desiredAngle, marginOfErrorForAngle: marginOfErrorForAngle, currentDeviceOrientation: currentDeviceOrientation, isAngleReadyToCapture: isAngleReadyToCapture, isShowingDeviceOrientationNotValidDisclaimer: isShowingDeviceOrientationNotValidDisclaimer, onBack: {
                    self.capturedAngle = nil
                    changeCurrentStep(to: .chooseAngle)
                }, onContinue: { angle in
                    self.capturedAngle = angle
                    changeCurrentStep(to: .setup)
                })
            case .setup:
                SetupStepView(onBack: { changeCurrentStep(to: isAngleSkipped ? .chooseAngle : .determineAngle) }, onContinue: { changeCurrentStep(to: .record) })
            case .record:
                RecordStepView(captureManager: captureManager, onBack: { changeCurrentStep(to: .setup) }, onRecord: startRecording, onStop: { captureManager.stopRecording() }, onImported: { url in
                    loadClip(at: url)
                    changeCurrentStep(to: .calibrate)
                })
            case .calibrate:
                if let scrubber {
                    CalibrateStepView(scrubber: scrubber, calibration: calibration, onBack: {
                        discardClip()
                        changeCurrentStep(to: .record)
                    }, onContinue: { calibration in
                        self.calibration = calibration
                        changeCurrentStep(to: .track)
                    })
                }
            case .track:
                if let scrubber {
                    TrackStepView(scrubber: scrubber, points: $trackedPoints, onBack: { changeCurrentStep(to: .calibrate) }, onFinish: finishMeasuring)
                }
            case .completed:
                CompletedStepView(desiredAngle: isAngleSkipped ? nil : desiredAngle, capturedAngle: capturedAngle, splits: splits, csvURL: csvURL, onRetryExport: exportCSV, onExit: { resetRun(); changeCurrentStep(to: .idle) })
            }
        }
        // Check the step first so the body only observes `currentAngle` while determining the angle.
        .background((currentStep == .determineAngle && isAngleReadyToCapture) ? .green3.opacity(0.5) : .clear)
        .onDeviceRotation { newOrientation in
            guard newOrientation.isLandscape else { return }
            withAnimation { self.currentDeviceOrientation = newOrientation }
        }
        .onChange(of: scenePhase) { _, newPhase in
            // The camera can't run in the background, so a recording in progress is thrown away
            // rather than kept with a gap in it.
            updateCaptureSession(scenePhase: newPhase)
        }
        .onDisappear {
            captureManager.stop()
        }
    }

    private func changeCurrentStep(to step: CameraMethodStep) {
        withAnimation {
            self.currentStep = step
        }

        updateAngleUpdates()
        updateCaptureSession(scenePhase: scenePhase)

        // Keep the screen awake while the phone is on the track or filming, where nobody touches it.
        UIApplication.shared.isIdleTimerDisabled = [.determineAngle, .record].contains(step)
    }

    /// Runs angle updates only while determining the angle.
    private func updateAngleUpdates() {
        if currentStep == .determineAngle {
            angleManager.start()
        } else {
            angleManager.stop()
        }
    }

    /// Runs the camera only while the record step is on screen and the app is in the foreground.
    private func updateCaptureSession(scenePhase: ScenePhase) {
        if currentStep == .record && scenePhase != .background {
            Task { await captureManager.start() }
        } else {
            captureManager.stop()
        }
    }

    // MARK: - Run lifecycle
    // The only places that talk to the camera and the clip.

    private func startRecording() {
        captureManager.startRecording { url in
            // `nil` when the recording was discarded or couldn't be saved.
            guard let url, currentStep == .record else { return }

            loadClip(at: url)
            changeCurrentStep(to: .calibrate)
        }
    }

    private func loadClip(at url: URL) {
        let scrubber = VideoScrubber(url: url)
        self.scrubber = scrubber

        Task {
            await scrubber.load()
        }
    }

    /// Throws away the clip but keeps the angle, so another one can be chosen.
    private func discardClip() {
        self.scrubber = nil
        self.calibration = nil
        self.trackedPoints = []
        VideoClipStore.removeTempFiles()
    }

    private func finishMeasuring() {
        if let calibration, let frames = scrubber?.frames {
            self.splits = TrackGeometry.makeSplits(from: trackedPoints, calibration: calibration, seconds: frames.seconds(at:))
        }

        changeCurrentStep(to: .completed)
        exportCSV()
    }

    /// Clears everything belonging to the current run: collected data, angles, and exported files.
    private func resetRun() {
        discardClip()
        self.splits = []
        self.desiredAngle = ChooseAngleStepView.defaultAngle
        self.capturedAngle = nil
        self.isAngleSkipped = false
        CSVExporter.removeTempFiles()
        self.csvURL = nil
    }

    private func exportCSV() {
        self.csvURL = CSVExporter.writeTempFile(for: splits)
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
    CameraMethodView()
        .environment(AngleManager())
        .environment(CameraCaptureManager())
        .environment(MethodManager())
}
