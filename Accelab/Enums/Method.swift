//
//  Method.swift
//  Accelab
//

import SwiftUI

enum Method: String, CaseIterable, Identifiable {
    // Camera comes first so its card is the first on the screen where a method is chosen.
    case camera = "Camera"
    case sensor = "Sensor"

    var id: Self { self }

    var imageName: String {
        switch self {
        case .camera:
            return "camera.viewfinder"
        case .sensor:
            return "gyroscope"
        }
    }

    var color: Color {
        switch self {
        case .camera:
            return .green1
        case .sensor:
            return .green2
        }
    }

    /// The name used in links (`accelab://circular-motion/sensor`).
    var slug: String {
        rawValue.lowercased()
    }
}
