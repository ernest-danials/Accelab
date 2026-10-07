//
//  Method.swift
//  Accelab
//

import SwiftUI

enum Method: String, CaseIterable, Identifiable {
    // Camera comes first so the selection screen opens on it.
    case camera = "Camera"
    case sensor = "Sensor"
    
    var id: Self { self }
    
    /// The method the selection screen steers people towards.
    var isRecommended: Bool {
        switch self {
        case .camera:
            return true
        case .sensor:
            return false
        }
    }
    
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

    var description: String {
        switch self {
        case .camera:
            return "Film a cart, or a ball in flight, and track its motion from the video."
        case .sensor:
            return "Attach your iPhone to the cart and measure its motion with the built-in sensors."
        }
    }
}
