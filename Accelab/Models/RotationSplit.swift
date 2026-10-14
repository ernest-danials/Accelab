//
//  RotationSplit.swift
//  Accelab
//

import Foundation

/// One sample of a phone going round on a turntable: how fast it is turning and the acceleration it feels,
/// read from the gyroscope and the accelerometer rather than worked out from anything.
struct RotationSplit: Identifiable, Hashable, Sendable {
    let id = UUID()
    let timeElapsed: TimeInterval          // seconds since start
    let angularVelocity: Double            // rad/s, never negative: which way the turntable was spun doesn't matter
    let centripetalAcceleration: Double    // m/s², + towards the centre of the turntable
    let tangentialAcceleration: Double     // m/s², + in the direction of the spin (speeding up)
}
