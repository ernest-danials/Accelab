//
//  CameraMethodStep.swift
//  Accelab
//

import Foundation

/// The steps of the methods that film the motion: the camera method, and the projectile method, which
/// runs the same steps without the two that set the track's angle.
enum CameraMethodStep: CaseIterable, Identifiable {
    case idle, chooseAngle, determineAngle, setup, record, trim, calibrate, track, analyze, completed

    var id: Self { self }

    /// Steps that lay themselves out around their own title rather than under the shared one.
    var drawsOwnTitle: Bool {
        [.setup, .record, .trim, .calibrate, .track].contains(self)
    }

    /// The steps that are numbered for the user, in the order the method goes through them.
    static func numberedSteps(for method: Method) -> [CameraMethodStep] {
        let videoSteps: [CameraMethodStep] = [.setup, .record, .trim, .calibrate, .track]
        return method.measuresAngle ? [.chooseAngle, .determineAngle] + videoSteps : videoSteps
    }

    func title(for method: Method) -> String {
        switch self {
        case .idle:
            return method.rawValue
        case .chooseAngle:
            return "Choose the Angle"
        case .determineAngle:
            return "Determine the Angle"
        case .setup:
            return "Set Up Your Shot"
        case .record:
            return method == .projectile ? "Record the Flight" : "Record the Run"
        case .trim:
            return "Trim the Video"
        case .calibrate:
            return "Mark a Known Length"
        case .track:
            return "Track the \(method.subject.capitalized)"
        case .analyze:
            return "Analysing"
        case .completed:
            return "Completed"
        }
    }

    /// "Step 1" and so on, counted through the steps this method has.
    func subtitle(for method: Method) -> String {
        guard let index = Self.numberedSteps(for: method).firstIndex(of: self) else { return "" }
        return "Step \(index + 1)"
    }

    func description(for method: Method) -> String {
        switch self {
        case .idle:
            return method.description
        case .chooseAngle:
            return "Choose the desired slope of your track."
        case .determineAngle:
            return "Measure and determine the slope of your track so it matches your desired slope."
        case .setup:
            return method == .projectile ? "Prop your iPhone level and square-on to the ball's flight, with a known length visible beside it." : "Prop your iPhone so it faces the track square-on, with a known length visible along the track."
        case .record:
            return method == .projectile ? "Start recording, launch the ball, and stop once it lands." : "Start recording, release the cart, and stop once it reaches the end of the track."
        case .trim:
            return method == .projectile ? "Keep only the flight, from the launch to the landing." : "Keep only the run, from the release to the end of the track."
        case .calibrate:
            return "Drag the two markers onto the ends of the known length and enter how long it is."
        case .track:
            return method == .projectile ? "Follow the ball automatically, or mark it by hand, frame by frame." : "Follow the cart automatically, or switch on Tap and mark the same spot on it frame by frame."
        case .analyze:
            return method == .projectile ? "Turning the tracked points into x and y against time." : "Turning the tracked points into distance and time."
        case .completed:
            return "Your lab data is ready for analysis! It's saved in Past Runs."
        }
    }
}
