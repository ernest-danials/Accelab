//
//  Method.swift
//  Accelab
//

import SwiftUI

enum Method: String, CaseIterable, Identifiable {
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

    var description: String {
        switch self {
        case .camera:
            return "Film the cart with your iPhone's camera and track its motion from the video."
        case .sensor:
            return "Attach your iPhone to the cart and measure its motion with the built-in sensors."
        }
    }
}
