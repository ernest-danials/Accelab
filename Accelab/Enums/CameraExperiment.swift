//
//  CameraExperiment.swift
//  Accelab
//

import Foundation

/// What the camera method is filming. Both run the same steps on the video; they differ in whether there
/// is a track whose angle is set first, and in what the tracked points become.
enum CameraExperiment: String, CaseIterable, Identifiable {
    /// A cart on a sloped track: distance along the track against time.
    case airTrack = "Air Track"
    /// An object in flight: x and y from where it started against time.
    case projectile = "Projectile"

    var id: Self { self }

    /// `true` when there is a track, whose angle is set before filming. A projectile has none.
    var measuresAngle: Bool {
        switch self {
        case .airTrack:
            return true
        case .projectile:
            return false
        }
    }

    var imageName: String {
        switch self {
        case .airTrack:
            return Method.camera.imageName
        case .projectile:
            return "circle.dotted.and.circle"
        }
    }

    /// Shown under the method's name on its start screen, in place of the method's own description.
    var description: String {
        switch self {
        case .airTrack:
            return "Film the cart with your iPhone's camera and track its motion from the video."
        case .projectile:
            return "Film an object in flight and track its x and y position from the video."
        }
    }

    /// What is followed through the video, as it is named in the instructions.
    var subject: String {
        switch self {
        case .airTrack:
            return "cart"
        case .projectile:
            return "object"
        }
    }
}
