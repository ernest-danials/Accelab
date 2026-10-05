//
//  CameraMethodStep.swift
//  Accelab
//

import Foundation

enum CameraMethodStep: CaseIterable, Identifiable {
    case idle, chooseAngle, determineAngle, setup, record, trim, calibrate, track, analyze, completed

    var id: Self { self }

    /// Steps that lay themselves out around their own title rather than under the shared one.
    var drawsOwnTitle: Bool {
        [.setup, .record, .trim, .calibrate, .track].contains(self)
    }

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
        case .trim:
            return "Trim the Video"
        case .calibrate:
            return "Mark a Known Length"
        case .track:
            return "Track the Cart"
        case .analyze:
            return "Analysing"
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
        case .trim:
            return "Step 5"
        case .calibrate:
            return "Step 6"
        case .track:
            return "Step 7"
        case .analyze, .completed:
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
        case .trim:
            return "Keep only the run, from the release to the end of the track."
        case .calibrate:
            return "Drag the two markers onto the ends of the known length and enter how long it is."
        case .track:
            return "Follow the cart automatically, or switch on Tap and mark the same spot on it frame by frame."
        case .analyze:
            return "Turning the tracked points into distance and time."
        case .completed:
            return "Your lab data is ready for analysis! Make sure to save it before exiting."
        }
    }
}
