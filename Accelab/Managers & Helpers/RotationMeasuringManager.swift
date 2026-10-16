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
/// accelerometer says at rest (its own offset, a few hundredths of a g on some phones); `beginRecording()`
/// then takes that as the bias and starts collecting samples. A turntable that isn't level is not
/// corrected for: its leak of gravity turns with the phone and averages out over whole turns.
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
    private var binner: RotationSampling.Binner? = nil

    // MARK: - Lifecycle

    func reset() {
        stop()
        splits.removeAll()
        restReadings.removeAll()
        binner = nil
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
        // Timed from now rather than from the first reading, so t = 0 is when the countdown ended.
        binner = RotationSampling.Binner(startTime: ProcessInfo.processInfo.systemUptime, sampleHz: sampleHz, bias: bias)
        isRecording = true
    }

    func stop() {
        guard isRunning else { return }
        motionManager.stopDeviceMotionUpdates()
        isRunning = false

        // The bin being filled when the run ended is kept: it says when the run ended.
        if isRecording, let split = binner?.flush() {
            splits.append(split)
        }
        isRecording = false
    }
}
