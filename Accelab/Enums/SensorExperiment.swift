//
//  SensorExperiment.swift
//  Accelab
//

import Foundation

/// What the sensor method is measuring. Both put the phone on the thing that moves; they differ in whether
/// there is a track whose angle is set first, and in which sensors are read.
enum SensorExperiment: String, CaseIterable, Identifiable {
    /// The phone rides a cart down a sloped track: distance along the track against time.
    case airTrack = "Air Track"
    /// The phone lies on a turntable: its angular velocity and centripetal acceleration against time.
    case circularMotion = "Circular Motion"

    var id: Self { self }

    /// `true` when there is a track, whose angle is set before measuring. A turntable has none.
    var measuresAngle: Bool {
        switch self {
        case .airTrack:
            return true
        case .circularMotion:
            return false
        }
    }

    var imageName: String {
        switch self {
        case .airTrack:
            return Method.sensor.imageName
        case .circularMotion:
            return "arrow.trianglehead.2.clockwise.rotate.90"
        }
    }

    /// Shown under the method's name on its start screen, in place of the method's own description.
    var description: String {
        switch self {
        case .airTrack:
            return "Attach your iPhone to the cart and measure its motion with the built-in sensors."
        case .circularMotion:
            return "Lay your iPhone on a turntable and measure its spin and centripetal acceleration with the built-in sensors."
        }
    }
}
