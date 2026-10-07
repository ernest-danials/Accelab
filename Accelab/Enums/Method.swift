//
//  Method.swift
//  Accelab
//

import SwiftUI

enum Method: String, CaseIterable, Identifiable {
    // Camera comes first so the selection screen opens on it.
    case camera = "Camera"
    case sensor = "Sensor"
    case projectile = "Projectile"

    var id: Self { self }

    /// The method the selection screen steers people towards.
    var isRecommended: Bool {
        switch self {
        case .camera:
            return true
        case .sensor, .projectile:
            return false
        }
    }

    /// `true` for the methods that film the motion and read it from the video.
    var usesCamera: Bool {
        switch self {
        case .camera, .projectile:
            return true
        case .sensor:
            return false
        }
    }

    /// `true` for the methods that run on a sloped track, whose angle is set first. A projectile has no track.
    var measuresAngle: Bool {
        switch self {
        case .camera, .sensor:
            return true
        case .projectile:
            return false
        }
    }

    var imageName: String {
        switch self {
        case .camera:
            return "camera.viewfinder"
        case .sensor:
            return "gyroscope"
        case .projectile:
            return "circle.dotted.and.circle"
        }
    }

    var color: Color {
        switch self {
        case .camera:
            return .green1
        case .sensor:
            return .green2
        case .projectile:
            // The darkest of the app's greens: the palest, `.green3`, leaves white text on it hard to read.
            return .accent
        }
    }

    var description: String {
        switch self {
        case .camera:
            return "Film the cart with your iPhone's camera and track its motion from the video."
        case .sensor:
            return "Attach your iPhone to the cart and measure its motion with the built-in sensors."
        case .projectile:
            return "Film a ball in flight with your iPhone's camera and track its x and y position from the video."
        }
    }

    /// What the method follows, as it is named in the instructions.
    var subject: String {
        switch self {
        case .camera, .sensor:
            return "cart"
        case .projectile:
            return "ball"
        }
    }
}
