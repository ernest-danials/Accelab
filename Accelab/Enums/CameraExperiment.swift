//
//  CameraExperiment.swift
//  Accelab
//

import Foundation

/// What the camera method is filming. All three run the same steps on the video; they differ in what comes
/// before (a track whose angle is set, a phone to level, or neither) and in what the tracked points become.
enum CameraExperiment: String, CaseIterable, Identifiable {
    /// A cart on a sloped track: distance along the track against time.
    case airTrack = "Air Track"
    /// An object in flight: x and y from where it started against time.
    case projectile = "Projectile"
    /// A marker going round, filmed from above: x, y and angle about the centre of its circle against time.
    case circularMotion = "Circular Motion"

    var id: Self { self }

    /// `true` when there is a track, whose angle is set before filming. A projectile and a circle have none.
    var measuresAngle: Bool {
        switch self {
        case .airTrack:
            return true
        case .projectile, .circularMotion:
            return false
        }
    }

    /// `true` when the phone is levelled with its sensors before filming. Only a projectile's x and y
    /// follow the picture's edges closely enough for that to matter; a circle filmed from above is barely
    /// changed by a small tilt, and a phone looking straight down is lying flat, which the angle reading refuses.
    var levelsPhone: Bool {
        switch self {
        case .airTrack, .circularMotion:
            return false
        case .projectile:
            return true
        }
    }

    var imageName: String {
        switch self {
        case .airTrack:
            return Method.camera.imageName
        case .projectile:
            return "circle.dotted.and.circle"
        case .circularMotion:
            return "circle.dotted.circle"
        }
    }

    /// What is followed through the video, as it is named in the instructions.
    var subject: String {
        switch self {
        case .airTrack:
            return "cart"
        case .projectile:
            return "object"
        case .circularMotion:
            return "marker"
        }
    }
}
