//
//  CameraMethodStep.swift
//  Accelab
//

import Foundation

/// The steps of the camera method. A projectile and a marker going round run the same steps on the video
/// as a cart on a track. Before them neither has a track whose angle is set; a projectile levels the phone
/// instead and a circle filmed from above has nothing to set, so the numbering and the wording follow what
/// is being filmed.
enum CameraMethodStep: CaseIterable, Identifiable {
    case idle, chooseAngle, determineAngle, setup, level, record, trim, calibrate, track, analyze, completed

    var id: Self { self }

    /// Steps that lay themselves out around their own title rather than under the shared one.
    var drawsOwnTitle: Bool {
        [.setup, .record, .trim, .calibrate, .track].contains(self)
    }

    /// The steps that are numbered for the user, in the order this experiment goes through them.
    static func numberedSteps(for experiment: CameraExperiment) -> [CameraMethodStep] {
        let videoSteps: [CameraMethodStep] = [.record, .trim, .calibrate, .track]
        if experiment.measuresAngle {
            return [.chooseAngle, .determineAngle, .setup] + videoSteps
        } else if experiment.levelsPhone {
            return [.setup, .level] + videoSteps
        } else {
            return [.setup] + videoSteps
        }
    }

    func title(for experiment: CameraExperiment) -> String {
        switch self {
        case .idle:
            return Method.camera.rawValue
        case .chooseAngle:
            return "Choose the Angle"
        case .determineAngle:
            return "Determine the Angle"
        case .setup:
            return "Set Up Your Shot"
        case .level:
            return "Level Your iPhone"
        case .record:
            switch experiment {
            case .airTrack:
                return "Record the Run"
            case .projectile:
                return "Record the Flight"
            case .circularMotion:
                return "Record the Turns"
            }
        case .trim:
            return "Trim the Video"
        case .calibrate:
            return "Mark a Known Length"
        case .track:
            return "Track the \(experiment.subject.capitalized)"
        case .analyze:
            return "Analysing"
        case .completed:
            return "Completed"
        }
    }

    /// "Step 1" and so on, counted through the steps this experiment has.
    func subtitle(for experiment: CameraExperiment) -> String {
        guard let index = Self.numberedSteps(for: experiment).firstIndex(of: self) else { return "" }
        return "Step \(index + 1)"
    }

    func description(for experiment: CameraExperiment) -> String {
        switch self {
        case .idle:
            return experiment.description
        case .chooseAngle:
            return "Choose the desired slope of your track."
        case .determineAngle:
            return "Measure and determine the slope of your track so it matches your desired slope."
        case .setup:
            switch experiment {
            case .airTrack:
                return "Prop your iPhone so it faces the track square-on, with a known length visible along the track."
            case .projectile:
                return "Prop your iPhone level and square-on to the flight, with a known length visible beside it."
            case .circularMotion:
                return "Prop your iPhone above the circle, looking straight down, with a known length visible beside it."
            }
        case .level:
            return "Prop your iPhone where it will film, then adjust it until it sits level."
        case .record:
            switch experiment {
            case .airTrack:
                return "Start recording, release the cart, and stop once it reaches the end of the track."
            case .projectile:
                return "Start recording, launch the object, and stop once it lands."
            case .circularMotion:
                return "Start recording, set the marker going round, and stop after a few turns."
            }
        case .trim:
            switch experiment {
            case .airTrack:
                return "Keep only the run, from the release to the end of the track."
            case .projectile:
                return "Keep only the flight, from the launch to the landing."
            case .circularMotion:
                return "Keep only the turns, from when the marker is set going."
            }
        case .calibrate:
            return "Drag the two markers onto the ends of the known length and enter how long it is."
        case .track:
            switch experiment {
            case .airTrack:
                return "Follow the cart automatically, or switch on Tap and mark the same spot on it frame by frame."
            case .projectile:
                return "Follow the object automatically, or mark it by hand, frame by frame."
            case .circularMotion:
                return "Follow the marker automatically, or mark it by hand, frame by frame."
            }
        case .analyze:
            switch experiment {
            case .airTrack:
                return "Turning the tracked points into distance and time."
            case .projectile:
                return "Turning the tracked points into x and y against time."
            case .circularMotion:
                return "Turning the tracked points into x, y and angle against time."
            }
        case .completed:
            return "Your lab data is ready for analysis! It's saved in Past Runs."
        }
    }
}
