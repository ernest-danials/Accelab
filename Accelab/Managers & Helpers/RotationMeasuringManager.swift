//
//  RotationMeasuringManager.swift
//  Accelab
//

import Foundation
import Observation
import CoreMotion

/// Measures a turntable's angular velocity and the acceleration on it from the phone's own sensors while it
/// lies flat on the turntable. Unlike `MotionMeasuringManager` it integrates nothing: the gyroscope gives
/// the angular velocity and the accelerometer the acceleration outright, and the samples are their means
/// over short bins.
///
/// It runs in two stages. `start()` begins reading while the turntable still stands, to learn what the
/// sensors say at rest (the accelerometer's own offset, a few hundredths of a g on some phones);
/// `beginRecording()` then takes that as the bias and starts collecting samples. The splits that appear
/// while recording have only that rest bias taken off; `stop()` remakes them all from the kept readings
/// with the gravity leak of a turntable that isn't level fitted and taken off too (see
/// `RotationSampling`), which needs the whole recording. Read `splits` after `stop()` for the run's data.
@Observable
final class RotationMeasuringManager {
    private(set) var splits: [RotationSplit] = []

    // Tunables
    /// How many samples a second end up in the data. Each is the mean of the readings in its bin.
    var sampleHz: Double = 10.0
    /// How often the sensors are read; the most CoreMotion offers.
    private let updateHz: Double = 100.0

    // Motion
    private let motionManager = CMMotionManager()
    private var isRunning = false
    private var isRecording = false

    // Readings taken while the turntable stands still, before recording.
    private var restReadings: [RotationSampling.Reading] = []
    // Every reading since `beginRecording()`, for the final splits; and the live binner for the ones shown meanwhile.
    private var recordedReadings: [RotationSampling.Reading] = []
    private var binner: RotationSampling.Binner? = nil
    /// The gravity leak fitted to the last recording, in g, or `nil` when the phone didn't turn enough to
    /// fit one (or no recording has finished). Its `amplitude` is g·sin(tilt): how level the table was.
    private(set) var leak: RotationSampling.Leak? = nil

    // MARK: - Lifecycle

    func reset() {
        stopSensors()
        splits.removeAll()
        restReadings.removeAll()
        recordedReadings.removeAll()
        binner = nil
        leak = nil
    }

    /// Starts reading the sensors, taking the phone to be at rest until `beginRecording()`.
    func start() {
        guard !isRunning else { return }
        isRunning = true
        isRecording = false
        restReadings.removeAll()

        motionManager.deviceMotionUpdateInterval = 1.0 / updateHz
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { [weak self] motion, _ in
            guard let self, let m = motion else { return }

            // `userAcceleration` is the accelerometer less CoreMotion's estimate of gravity, and that
            // estimate comes from a filter that can't tell a steady sideways acceleration from a tilt, so
            // seconds of going round may bend it. Adding gravity back gives the accelerometer's own
            // reading in the phone's axes, with no estimate in it; lying flat, its x and y are the motion.
            let reading = RotationSampling.Reading(timestamp: m.timestamp, rotationRateZ: m.rotationRate.z, accelerationX: m.userAcceleration.x + m.gravity.x, accelerationY: m.userAcceleration.y + m.gravity.y)

            if self.isRecording {
                self.recordedReadings.append(reading)
                if let split = self.binner?.add(reading) {
                    self.splits.append(split)
                }
            } else {
                self.restReadings.append(reading)
            }
        }
    }

    /// Starts collecting samples, with the readings so far as the reading at rest. Starts the sensors
    /// first if `start()` wasn't called, in which case there is no rest reading to subtract.
    func beginRecording() {
        start()
        let bias = RotationSampling.makeBias(from: restReadings)
        restReadings.removeAll()
        recordedReadings.removeAll()
        leak = nil
        // Timed from now rather than from the first reading, so t = 0 is when the countdown ended.
        binner = RotationSampling.Binner(startTime: ProcessInfo.processInfo.systemUptime, sampleHz: sampleHz, bias: bias)
        isRecording = true
    }

    /// Stops the sensors and, if recording, replaces the live splits with the whole recording's, with the
    /// tilt leak taken off.
    func stop() {
        guard isRunning else { return }
        let wasRecording = isRecording
        stopSensors()

        if wasRecording, let binner {
            // The bin being filled when the run ended is kept: it says when the run ended.
            let result = RotationSampling.makeSplits(from: recordedReadings, bias: binner.bias, startTime: binner.startTime, sampleHz: binner.sampleHz)
            splits = result.splits
            leak = result.leak
            recordedReadings.removeAll()
        }
    }

    private func stopSensors() {
        guard isRunning else { return }
        motionManager.stopDeviceMotionUpdates()
        isRunning = false
        isRecording = false
    }
}
