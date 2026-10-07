//
//  CameraMethodStep.swift
//  Accelab
//

import Foundation

/// The steps of the camera method. A projectile runs the same steps on the video as a cart on a track.
/// Before them it has no track whose angle is set, and levels the phone instead, so the numbering and the
/// wording follow what is being filmed.
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
        return experiment.measuresAngle ? [.chooseAngle, .determineAngle, .setup] + videoSteps : [.setup, .level] + videoSteps
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
            return experiment == .projectile ? "Record the Flight" : "Record the Run"
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
            return experiment == .projectile ? "Prop your iPhone level and square-on to the flight, with a known length visible beside it." : "Prop your iPhone so it faces the track square-on, with a known length visible along the track."
        case .level:
            return "Prop your iPhone where it will film, then adjust it until it sits level."
        case .record:
            return experiment == .projectile ? "Start recording, launch the object, and stop once it lands." : "Start recording, release the cart, and stop once it reaches the end of the track."
        case .trim:
            return experiment == .projectile ? "Keep only the flight, from the launch to the landing." : "Keep only the run, from the release to the end of the track."
        case .calibrate:
            return "Drag the two markers onto the ends of the known length and enter how long it is."
        case .track:
            return experiment == .projectile ? "Follow the object automatically, or mark it by hand, frame by frame." : "Follow the cart automatically, or switch on Tap and mark the same spot on it frame by frame."
        case .analyze:
            return experiment == .projectile ? "Turning the tracked points into x and y against time." : "Turning the tracked points into distance and time."
        case .completed:
            return "Your lab data is ready for analysis! It's saved in Past Runs."
        }
    }
}
