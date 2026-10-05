//
//  CameraMethodView.swift
//  Accelab
//
//  Created by Myung Joon Kang on 2026-10-04.
//

import SwiftUI

struct CameraMethodView: View {
    @Environment(AngleManager.self) private var angleManager: AngleManager
    @Environment(MethodManager.self) private var methodManager: MethodManager

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
            StepTitleView(title: currentStep.title, subtitle: currentStep.subtitle, description: currentStep.description, isProminent: currentStep == .idle, isCompact: [.calibrate, .track].contains(currentStep))

            switch currentStep {
            case .idle:
                idleStepView
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
                placeholderStepView(onBack: { changeCurrentStep(to: isAngleSkipped ? .chooseAngle : .determineAngle) }, onContinue: { changeCurrentStep(to: .record) })
            case .record:
                RecordStepView(onBack: { changeCurrentStep(to: .setup) }, onImported: { url in
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
    }

    private var idleStepView: some View {
        ZStack {
            Image(systemName: Method.camera.imageName)
                .customFont(.largeTitle, weight: .medium)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Method.camera.color)
                .frame(width: 90, height: 90)
                .glassEffect(.regular, in: .circle)

            GlassButton(text: "Change Method", style: .secondary) {
                methodManager.changeMethod(to: nil)
            }
            .alignView(to: .leading)
            .alignViewVertically(to: .bottom)
            .padding()

            GlassButton(text: "Start") {
                changeCurrentStep(to: .chooseAngle)
            }
            .alignView(to: .trailing)
            .alignViewVertically(to: .bottom)
            .padding()
        }
    }

    // TODO: Replace with a real view per step in `Views/Camera Method/Steps/`.
    private func placeholderStepView(onBack: @escaping () -> Void, onContinue: @escaping () -> Void) -> some View {
        ZStack {
            Text("Coming Soon")
                .customFont(.title3, weight: .bold)
                .foregroundStyle(.secondary)

            GlassEffectContainer {
                HStack {
                    GlassButton(text: "Back", style: .secondary, perform: onBack)

                    GlassButton(text: "Continue", perform: onContinue)
                }
                .alignView(to: .trailing)
                .alignViewVertically(to: .bottom)
                .padding()
            }
        }
    }

    private func changeCurrentStep(to step: CameraMethodStep) {
        withAnimation {
            self.currentStep = step
        }

        updateAngleUpdates()

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

    // MARK: - Run lifecycle

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
        .environment(MethodManager())
}
