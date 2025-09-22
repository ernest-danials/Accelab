//
//  MeasuringManager.swift
//  Accelab
//
//  Created by Myung Joon Kang on 2025-09-21.
//

import Foundation
import Observation
import CoreMotion

@Observable
final class MeasuringManager {
    private(set) var splits: [DistanceSplit] = []

    // Convenience readouts for the UI
    var elapsed: TimeInterval { (lastT == 0 ? 0 : lastT - t0) }
    var distance: Double { s }

    // Tunables (can be adjusted from UI if desired)
    var sampleHz: Double = 10.0
    var tinyAThreshold: Double = 0.03      // m/s^2 threshold to treat as near-zero accel
    var smallAccelDamping: Double = 0.02   // pulls velocity toward 0 when |a| is tiny

    // Motion
    private let motionManager = CMMotionManager()
    private var isRunning = false

    // Integration state
    private var t0: TimeInterval = 0
    private var lastT: TimeInterval = 0
    private var v: Double = 0      // m/s
    private var s: Double = 0      // m
    private var lastA: Double = 0  // m/s^2

    // MARK: - Lifecycle
    func reset() {
        stop(applyZeroVelocitySnap: false)
        splits.removeAll()
        t0 = 0; lastT = 0
        v = 0; s = 0; lastA = 0
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true

        motionManager.deviceMotionUpdateInterval = 1.0 / sampleHz
        // Use xArbitraryZVertical so gravity is stable and userAcceleration excludes g
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { [weak self] motion, _ in
            guard let self, let m = motion else { return }

            let now = m.timestamp
            if self.t0 == 0 { self.t0 = now; self.lastT = now }

            // Acceleration along the track (device long edge = Y axis), in m/s^2
            // userAcceleration has gravity removed; multiply by g0 to convert from g's.
            let g0 = 9.80665
            let aY = -m.userAcceleration.y * g0

            // Time step
            let dt = max(0, now - self.lastT)

            // Light bias control to curb drift when nearly still
            var a = aY
            if abs(a) < self.tinyAThreshold {
                a -= self.smallAccelDamping * self.v / max(dt, 1e-3)
            }

            // Integrate a -> v (trapezoid), then v -> s
            let vNew = self.v + 0.5 * (self.lastA + a) * dt
            let sNew = self.s + 0.5 * (self.v + vNew) * dt

            self.v = vNew
            self.s = sNew
            self.lastA = a
            self.lastT = now

            // Store sample (time since start, displacement, along-track accel)
            let tRel = now - self.t0
            self.splits.append(DistanceSplit(timeElapsed: tRel, displacement: sNew, acceleration: a))
        }
    }

    func stop(applyZeroVelocitySnap: Bool = true) {
        guard isRunning else { return }
        motionManager.stopDeviceMotionUpdates()
        isRunning = false

        // Optionally snap terminal velocity to 0 if it's small, to reduce end drift
        if applyZeroVelocitySnap, let last = splits.last, abs(v) < 0.2 {
            v = 0
            splits.append(DistanceSplit(timeElapsed: last.timeElapsed, displacement: s, acceleration: 0))
        }
    }

    // MARK: - Export
    func makeCSV() -> String {
        var rows = ["time_s,distance_m"]
        rows.reserveCapacity(splits.count + 1)
        for smp in splits {
            rows.append(String(format: "%.4f,%.5f", smp.timeElapsed, smp.displacement))
        }
        return rows.joined(separator: "\n")
    }
}

// MARK: - Model
struct DistanceSplit: Identifiable, Hashable, Sendable {
    let id = UUID()
    let timeElapsed: TimeInterval   // seconds since start
    let displacement: Double         // meters (displacement along track, + down-slope)
    let acceleration: Double         // m/s^2 along track (optional; useful for checks)
}
