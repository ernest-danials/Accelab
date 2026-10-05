//
//  CameraMethodStep.swift
//  Accelab
//

import Foundation

enum CameraMethodStep: CaseIterable, Identifiable {
    case idle, chooseAngle, determineAngle, setup, record, calibrate, track, completed

    var id: Self { self }

    var title: String {
        switch self {
        case .idle:
            return Method.camera.rawValue
        case .chooseAngle:
            return "Choose the Angle"
        case .determineAngle:
            return "Determine the Angle"
        case .setup:
            return "Set Up Your Shot"
        case .record:
            return "Record the Run"
        case .calibrate:
            return "Mark a Known Length"
        case .track:
            return "Track the Cart"
        case .completed:
            return "Completed"
        }
    }

    var subtitle: String {
        switch self {
        case .idle:
            return ""
        case .chooseAngle:
            return "Step 1"
        case .determineAngle:
            return "Step 2"
        case .setup:
            return "Step 3"
        case .record:
            return "Step 4"
        case .calibrate:
            return "Step 5"
        case .track:
            return "Step 6"
        case .completed:
            return ""
        }
    }

    var description: String {
        switch self {
        case .idle:
            return Method.camera.description
        case .chooseAngle:
            return "Choose the desired slope of your track."
        case .determineAngle:
            return "Measure and determine the slope of your track so it matches your desired slope."
        case .setup:
            return "Prop your iPhone so it faces the track square-on, with a known length visible along the track."
        case .record:
            return "Start recording, release the cart, and stop once it reaches the end of the track."
        case .calibrate:
            return "Drag the two markers onto the ends of the known length and enter how long it is."
        case .track:
            return "Mark where the cart is so Accelab can follow it through the video."
        case .completed:
            return "Your lab data is ready for analysis! Make sure to save it before exiting."
        }
    }
}
