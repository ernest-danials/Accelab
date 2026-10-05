//
//  AngleManager.swift
//  Accelab
//
//  Created by Myung Joon Kang on 2025-09-20.
//

import SwiftUI
import CoreMotion
import simd

@Observable
final class AngleManager {
    var currentAngle: Double = 0.0
    var rawAngle: Double = 0.0  // 0..180°, used for visual quadrant/anchor logic
    var isFlat: Bool = false    // lying face up/down, where the slope of the long edge can't be read
    /// Which way round the phone is actually being held, read from gravity. `nil` while it can't be told.
    /// Unlike the interface's side, this keeps following the phone when Orientation Lock is on.
    var physicalLandscapeSide: UIDeviceOrientation? = nil
    
    private let motionManager = CMMotionManager()
    private var lpAngle: Double = 0
    private var isRunning = false

    func start() {
        guard !isRunning else { return }
        isRunning = true

        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }

            // Gravity vector
            let g = motion.gravity
            let gravity = simd_double3(g.x, g.y, g.z)

            // Detect lying flat from gravity rather than `UIDevice.orientation`, which stops updating under
            // orientation lock. The two thresholds keep the state from flickering at the boundary.
            let flatness = abs(simd_normalize(gravity).z)
            if self.isFlat ? flatness < 0.8 : flatness > 0.9 {
                withAnimation { self.isFlat.toggle() }
            }
            // In landscape the short edge (device X) is the one pointing up or down, so the sign of gravity
            // along it tells the two landscape sides apart.
            let sideways = simd_normalize(gravity).x
            let physicalSide: UIDeviceOrientation? = (self.isFlat || abs(sideways) < 0.3) ? nil : (sideways < 0 ? .landscapeLeft : .landscapeRight)
            if physicalSide != self.physicalLandscapeSide {
                self.physicalLandscapeSide = physicalSide
            }

            guard !self.isFlat else { return }

            // Angle between gravity (vertical) and device Y-axis (long edge)
            let deviceY = simd_double3(0, 1, 0)
            var cosPhi = simd_dot(simd_normalize(gravity), simd_normalize(deviceY))
            cosPhi = max(-1.0, min(1.0, cosPhi))
            let phi = acos(cosPhi) // radians, 0..π

            // Signed angle in degrees (−90..+90)
            let signedDeg = ((.pi / 2) - phi) * 180 / .pi

            // Low‑pass the signed angle for a stable visual. Filtering must happen here, not on the
            // 0..180° raw angle, which wraps around at horizontal (0.1° ↔ 179.9°) and would average noise into garbage.
            let alpha = 0.15
            self.lpAngle = alpha * signedDeg + (1 - alpha) * self.lpAngle

            // Map to raw 0..180° to know which side of horizontal we’re on
            let rawDeg = self.lpAngle >= 0 ? self.lpAngle : (180 + self.lpAngle) // e.g., −10° → 170°

            withAnimation {
                self.rawAngle = rawDeg
                self.currentAngle = abs(self.lpAngle)
            }
        }
    }

    func stop() {
        guard isRunning else { return }
        motionManager.stopDeviceMotionUpdates()
        isRunning = false
        physicalLandscapeSide = nil
    }
    
    func isCurrentAngleWithinMargin(targetAngle: Double, margin: Double) -> Bool {
        return (abs(targetAngle - self.currentAngle) <= margin)
    }
}
