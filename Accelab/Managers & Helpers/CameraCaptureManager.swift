//
//  CameraCaptureManager.swift
//  Accelab
//

import AVFoundation
import Observation

/// Records a clip of the run with settings chosen for measuring from it: a fixed 60 fps, no stabilisation
/// (which warps the frame), no audio, and focus, exposure and white balance held still while recording.
@Observable
final class CameraCaptureManager: NSObject, AVCaptureFileOutputRecordingDelegate {
    enum State {
        case idle, starting, unauthorized, unavailable, ready, recording, finishing
    }

    private(set) var state: State = .idle
    private(set) var recordingStartDate: Date? = nil

    @ObservationIgnored nonisolated(unsafe) let session = AVCaptureSession()
    @ObservationIgnored nonisolated(unsafe) private let movieOutput = AVCaptureMovieFileOutput()
    @ObservationIgnored private var device: AVCaptureDevice? = nil
    @ObservationIgnored private var rotationCoordinator: AVCaptureDevice.RotationCoordinator? = nil
    @ObservationIgnored private var isSessionConfigured: Bool = false
    @ObservationIgnored private var onFinished: ((URL?) -> Void)? = nil
    @ObservationIgnored private var isDiscardingRecording: Bool = false

    nonisolated private static let frameRate: Int32 = 60
    /// A run takes a few seconds; this only stops a forgotten recording from filling the disk.
    nonisolated private static let maximumDuration: TimeInterval = 60

    /// Asks for camera access if needed and starts the preview.
    func start() async {
        guard state == .idle || state == .unauthorized || state == .unavailable else { return }

        self.state = .starting

        guard await AVCaptureDevice.requestAccess(for: .video) else {
            self.state = .unauthorized
            return
        }

        if !isSessionConfigured {
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back), let input = try? AVCaptureDeviceInput(device: device) else {
                self.state = .unavailable
                return
            }

            let session = self.session
            let movieOutput = self.movieOutput
            let didConfigure = await Task.detached { Self.configure(session, device: device, input: input, movieOutput: movieOutput) }.value

            guard didConfigure else {
                self.state = .unavailable
                return
            }

            self.device = device
            self.isSessionConfigured = true
        }

        let session = self.session
        // `startRunning()` blocks until the camera is up.
        await Task.detached { session.startRunning() }.value

        // The step may have been left while the camera was starting.
        if state == .starting {
            self.state = .ready
        } else {
            Task.detached { session.stopRunning() }
        }
    }

    /// Stops the preview, discarding a recording in progress.
    func stop() {
        if state == .recording {
            stopRecording(discard: true)
        }

        let session = self.session
        Task.detached { session.stopRunning() }
        self.state = .idle
    }

    /// Lets the preview and the recording follow how the phone is being held.
    func attach(previewLayer: AVCaptureVideoPreviewLayer) -> AVCaptureDevice.RotationCoordinator? {
        guard let device else { return nil }

        let rotationCoordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: previewLayer)
        self.rotationCoordinator = rotationCoordinator
        return rotationCoordinator
    }

    /// - Parameter onFinished: Called with the clip's location, or `nil` if it was discarded or couldn't be saved.
    func startRecording(onFinished: @escaping (URL?) -> Void) {
        guard state == .ready, let device else { return }

        if let connection = movieOutput.connection(with: .video) {
            if let angle = rotationCoordinator?.videoRotationAngleForHorizonLevelCapture, connection.isVideoRotationAngleSupported(angle) {
                connection.videoRotationAngle = angle
            }
            if connection.isVideoStabilizationSupported {
                connection.preferredVideoStabilizationMode = .off
            }
        }

        // A tracker follows appearance, so nothing about the picture should shift mid-run.
        setCameraAdjustmentsLocked(true, on: device)

        self.onFinished = onFinished
        self.isDiscardingRecording = false
        self.recordingStartDate = Date()
        self.state = .recording
        movieOutput.startRecording(to: VideoClipStore.makeTempURL(pathExtension: "mov"), recordingDelegate: self)
    }

    func stopRecording(discard: Bool = false) {
        guard state == .recording else { return }

        self.isDiscardingRecording = discard
        self.state = .finishing
        movieOutput.stopRecording()
    }

    nonisolated func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        // Reaching the duration limit is reported as an error even though the file is complete.
        let didSucceed = error == nil || ((error as NSError?)?.userInfo[AVErrorRecordingSuccessfullyFinishedKey] as? Bool) == true

        Task { @MainActor in
            self.finishRecording(at: outputFileURL, didSucceed: didSucceed)
        }
    }

    private func finishRecording(at url: URL, didSucceed: Bool) {
        if let device {
            setCameraAdjustmentsLocked(false, on: device)
        }

        let shouldKeep = didSucceed && !isDiscardingRecording
        if !shouldKeep {
            try? FileManager.default.removeItem(at: url)
        }

        self.recordingStartDate = nil
        // `stop()` may already have moved on to idle.
        if state == .finishing || state == .recording {
            self.state = .ready
        }

        let onFinished = self.onFinished
        self.onFinished = nil
        onFinished?(shouldKeep ? url : nil)
    }

    private func setCameraAdjustmentsLocked(_ isLocked: Bool, on device: AVCaptureDevice) {
        guard (try? device.lockForConfiguration()) != nil else { return }
        defer { device.unlockForConfiguration() }

        let focusMode: AVCaptureDevice.FocusMode = isLocked ? .locked : .continuousAutoFocus
        if device.isFocusModeSupported(focusMode) { device.focusMode = focusMode }

        let exposureMode: AVCaptureDevice.ExposureMode = isLocked ? .locked : .continuousAutoExposure
        if device.isExposureModeSupported(exposureMode) { device.exposureMode = exposureMode }

        let whiteBalanceMode: AVCaptureDevice.WhiteBalanceMode = isLocked ? .locked : .continuousAutoWhiteBalance
        if device.isWhiteBalanceModeSupported(whiteBalanceMode) { device.whiteBalanceMode = whiteBalanceMode }
    }

    nonisolated private static func configure(_ session: AVCaptureSession, device: AVCaptureDevice, input: AVCaptureDeviceInput, movieOutput: AVCaptureMovieFileOutput) -> Bool {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        guard session.canAddInput(input), session.canAddOutput(movieOutput) else { return false }
        session.addInput(input)
        session.addOutput(movieOutput)
        movieOutput.maxRecordedDuration = CMTime(seconds: maximumDuration, preferredTimescale: 600)

        // 1080p at 60 fps. Of the formats that can do it, the one with the lowest top frame rate is the
        // ordinary full-sensor format rather than a slow-motion one.
        let candidates = device.formats.filter { format in
            let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            return dimensions.width == 1920 && dimensions.height == 1080 && format.videoSupportedFrameRateRanges.contains { $0.maxFrameRate >= Double(frameRate) }
        }
        let format = candidates.min { topFrameRate(of: $0) < topFrameRate(of: $1) }

        if let format, (try? device.lockForConfiguration()) != nil {
            // Setting the format switches the session to follow the device rather than a preset.
            device.activeFormat = format
            device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: frameRate)
            device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: frameRate)
            device.unlockForConfiguration()
        } else if session.canSetSessionPreset(.hd1920x1080) {
            session.sessionPreset = .hd1920x1080
        }

        return true
    }

    nonisolated private static func topFrameRate(of format: AVCaptureDevice.Format) -> Double {
        format.videoSupportedFrameRateRanges.map(\.maxFrameRate).max() ?? 0
    }
}
