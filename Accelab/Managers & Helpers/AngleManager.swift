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

            // Angle between gravity (vertical) and device Y-axis (long edge)
            let deviceY = simd_double3(0, 1, 0)
            var cosPhi = simd_dot(simd_normalize(gravity), simd_normalize(deviceY))
            cosPhi = max(-1.0, min(1.0, cosPhi))
            let phi = acos(cosPhi) // radians, 0..π

            // Signed angle in degrees (−90..+90)
            let signedDeg = ((.pi / 2) - phi) * 180 / .pi
            // Map to raw 0..180° to know which side of horizontal we’re on
            let rawDeg = signedDeg >= 0 ? signedDeg : (180 + signedDeg) // e.g., −10° → 170°

            // Low‑pass the raw angle for a stable visual
            let alpha = 0.15
            self.lpAngle = alpha * rawDeg + (1 - alpha) * self.lpAngle

            // Get acute angle for the label
            let acute = min(self.lpAngle, 180 - self.lpAngle)

            withAnimation {
                self.rawAngle = self.lpAngle
                self.currentAngle = acute
            }
        }
    }

    func stop() {
        guard isRunning else { return }
        motionManager.stopDeviceMotionUpdates()
        isRunning = false
    }
    
    func isCurrentAngleWithinMargin(targetAngle: Double, margin: Double) -> Bool {
        return (abs(targetAngle - self.currentAngle) <= margin)
    }
}
