//
//  CameraMethodView.swift
//  Accelab
//
//  Created by Myung Joon Kang on 2026-10-04.
//

import SwiftUI
import SwiftData

struct CameraMethodView: View {
    @Environment(AngleManager.self) private var angleManager: AngleManager
    @Environment(CameraCaptureManager.self) private var captureManager: CameraCaptureManager
    @Environment(MethodManager.self) private var methodManager: MethodManager
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

    @State private var currentStep: CameraMethodStep = .idle
    /// What is being filmed, chosen on the idle step. A projectile runs the same steps as a cart on a track
    /// without the two that set the track's angle, and ends with x and y against time rather than distance
    /// along the track. Kept across runs, so a class doing one lab doesn't choose again each time.
    @State private var experiment: CameraExperiment = .airTrack

    @State private var currentDeviceOrientation: UIDeviceOrientation? = nil

    @AppStorage(AppStorageKey.marginOfErrorForAngle.rawValue) private var marginOfErrorForAngle: Double = 0.1
    @State private var desiredAngle: Double = ChooseAngleStepView.defaultAngle
    @State private var capturedAngle: Double? = nil
    @State private var isAngleSkipped: Bool = false

    @State private var scrubber: VideoScrubber? = nil
    @State private var calibration: CameraCalibration? = nil
    @State private var trackedPoints: [TrackedPoint] = []

    @State private var data: RunData = .distance([])
    @State private var csvURL: URL? = nil
    @State private var desmosURL: URL? = nil
    /// `true` when the clip came from Photos, which already has it, so it isn't offered for export.
    @State private var isClipImported: Bool = false
    @State private var videoURL: URL? = nil
    @State private var photoURL: URL? = nil
    @State private var photoTask: Task<Void, Never>? = nil
    /// The current run in the past runs, once it has finished.
    @State private var savedRun: SavedRun? = nil

    var body: some View {
        ZStack {
            // The steps from setup to tracking lay themselves out around their own title.
            if !currentStep.drawsOwnTitle {
                StepTitleView(title: currentStep.title(for: experiment), subtitle: currentStep.subtitle(for: experiment), description: currentStep.description(for: experiment), isProminent: currentStep == .idle)
            }

            switch currentStep {
            case .idle:
                // A projectile has no track to set the angle of, so it goes straight to the shot.
                CameraIdleStepView(experiment: $experiment, onChangeMethod: { methodManager.changeMethod(to: nil) }, onStart: { changeCurrentStep(to: experiment.measuresAngle ? .chooseAngle : .setup) })
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
                SetupStepView(experiment: experiment, onBack: {
                    if experiment.measuresAngle {
                        changeCurrentStep(to: isAngleSkipped ? .chooseAngle : .determineAngle)
                    } else {
                        resetRun()
                        changeCurrentStep(to: .idle)
                    }
                }, onContinue: { changeCurrentStep(to: .record) })
            case .record:
                RecordStepView(experiment: experiment, captureManager: captureManager, onBack: { changeCurrentStep(to: .setup) }, onRecord: startRecording, onStop: { captureManager.stopRecording() }, onImported: { url in
                    loadClip(at: url, isImported: true)
                    changeCurrentStep(to: .trim)
                })
            case .trim:
                if let scrubber {
                    TrimStepView(experiment: experiment, scrubber: scrubber, onBack: {
                        discardClip()
                        changeCurrentStep(to: .record)
                    }, onContinue: {
                        // Points marked on an earlier pass may now lie outside the kept range.
                        self.trackedPoints.removeAll { !scrubber.trimRange.contains($0.frameIndex) }
                        scrubber.seek(toFrame: scrubber.trimRange.lowerBound)
                        changeCurrentStep(to: .calibrate)
                    })
                }
            case .calibrate:
                if let scrubber {
                    CalibrateStepView(experiment: experiment, scrubber: scrubber, calibration: calibration, onBack: { changeCurrentStep(to: .trim) }, onContinue: { calibration in
                        self.calibration = calibration
                        changeCurrentStep(to: .track)
                    })
                }
            case .track:
                if let scrubber {
                    TrackStepView(experiment: experiment, scrubber: scrubber, points: $trackedPoints, onBack: { changeCurrentStep(to: .calibrate) }, onFinish: finishMeasuring)
                }
            case .analyze:
                AnalyzeStepView(data: data, onFinished: { changeCurrentStep(to: .completed) })
            case .completed:
                CompletedStepView(desiredAngle: targetAngle, capturedAngle: capturedAngle, data: data, csvURL: csvURL, desmosURL: desmosURL, offersMedia: true, videoURL: videoURL, photoURL: photoURL, onRetryExport: exportCSV, onExit: { resetRun(); changeCurrentStep(to: .idle) })
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

            loadClip(at: url, isImported: false)
            changeCurrentStep(to: .trim)
        }
    }

    private func loadClip(at url: URL, isImported: Bool) {
        let scrubber = VideoScrubber(url: url)
        self.scrubber = scrubber
        self.isClipImported = isImported

        Task {
            await scrubber.load()
        }
    }

    /// Throws away the clip but keeps the angle, so another one can be chosen.
    private func discardClip() {
        self.scrubber = nil
        self.calibration = nil
        self.trackedPoints = []
        self.isClipImported = false
        VideoClipStore.removeTempFiles()
    }

    private func finishMeasuring() {
        if let calibration, let frames = scrubber?.frames {
            if experiment == .projectile {
                self.data = .position(TrackGeometry.makePositionSplits(from: trackedPoints, calibration: calibration, seconds: frames.seconds(at:)))
            } else {
                self.data = .distance(TrackGeometry.makeSplits(from: trackedPoints, calibration: calibration, seconds: frames.seconds(at:)))
            }
        }

        exportCSV()
        saveRun()
        exportMedia()
        changeCurrentStep(to: .analyze)
    }

    /// Keeps the finished run in the past runs. It stays there after `resetRun()`; its photo is added by `exportMedia()`.
    private func saveRun() {
        guard !data.isEmpty else { return }

        if let savedRun {
            savedRun.update(data: data)
        } else {
            let run = SavedRun(method: .camera, experiment: experiment, desiredAngle: targetAngle, capturedAngle: capturedAngle, data: data)
            modelContext.insert(run)
            self.savedRun = run
        }
    }

    /// Clears everything belonging to the current run: collected data, angles, and exported files.
    private func resetRun() {
        discardClip()
        self.data = .distance([])
        self.savedRun = nil
        self.desiredAngle = ChooseAngleStepView.defaultAngle
        self.capturedAngle = nil
        self.isAngleSkipped = false
        CSVExporter.removeTempFiles()
        self.csvURL = nil
        self.desmosURL = nil
        removeMedia()
    }

    private func exportCSV() {
        self.csvURL = CSVExporter.writeTempFile(for: data)
        self.desmosURL = CSVExporter.writeDesmosTempFile(for: data)
    }

    /// Prepares the clip (only one filmed here) and the photo of the tracked points for sharing.
    /// The photo is drawn while the analyze step is on screen.
    private func exportMedia() {
        removeMedia()
        guard let scrubber, let frames = scrubber.frames else { return }

        if !isClipImported {
            self.videoURL = RunMediaExporter.makeVideoFile(from: scrubber.url)
        }

        let points = trackedPoints
        let run = savedRun
        self.photoTask = Task {
            let url = await RunMediaExporter.makePhotoFile(from: scrubber.url, frames: frames, points: points)
            // The saved run keeps the photo even if this run was reset before it was drawn, unless it was deleted meanwhile.
            if let url, let run, !run.isDeleted, run.modelContext != nil, !Task.isCancelled || run.photo == nil, let data = try? Data(contentsOf: url) {
                run.photo = data
            }
            // Cancelled when the run was reset first, after which nothing would remove the photo.
            guard !Task.isCancelled else {
                if let url { try? FileManager.default.removeItem(at: url) }
                return
            }
            self.photoURL = url
        }
    }

    private func removeMedia() {
        photoTask?.cancel()
        self.photoTask = nil
        self.videoURL = nil
        self.photoURL = nil
        RunMediaExporter.removeTempFiles()
    }

    /// The angle the track was set to. `nil` when the angle steps were skipped, and for a projectile, which has none.
    private var targetAngle: Double? {
        experiment.measuresAngle && !isAngleSkipped ? desiredAngle : nil
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
        .modelContainer(for: SavedRun.self, inMemory: true)
}
