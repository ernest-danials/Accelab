//
//  SensorMethodStep.swift
//  Accelab
//
//  Created by Myung Joon Kang on 2025-09-21.
//

import Foundation

enum SensorMethodStep: CaseIterable, Identifiable {
    case chooseAngle, determineAngle, standby, countdown, measuring, completed
    
    var id: Self { self }

    /// Where a run starts: setting the track's angle, or straight to placing the phone on a turntable.
    static func firstStep(for experiment: SensorExperiment) -> SensorMethodStep {
        experiment.measuresAngle ? .chooseAngle : .standby
    }
    
    func title(for experiment: SensorExperiment) -> String {
        switch self {
        case .chooseAngle:
            return "Choose the Angle"
        case .determineAngle:
            return "Determine the Angle"
        case .standby:
            return experiment.measuresAngle ? "Attach Your iPhone to the Cart" : "Place Your iPhone on the Turntable"
        case .countdown:
            return "Get Ready"
        case .measuring:
            return "Collect Data"
        case .completed:
            return "Completed"
        }
    }
    
    /// "Step N". A turntable has no angle to set, so its steps start at the standby.
    func subtitle(for experiment: SensorExperiment) -> String {
        switch self {
        case .chooseAngle:
            return "Step 1"
        case .determineAngle:
            return "Step 2"
        case .standby:
            return experiment.measuresAngle ? "Step 3" : "Step 1"
        case .countdown:
            return experiment.measuresAngle ? "Step 4" : "Step 2"
        case .measuring:
            return experiment.measuresAngle ? "Step 4" : "Step 2"
        case .completed:
            return ""
        }
    }
    
    func description(for experiment: SensorExperiment) -> String {
        switch self {
        case .chooseAngle:
            return "Choose the desired slope of your track."
        case .determineAngle:
            return "Measure and determine the slope of your track so it matches your desired slope."
        case .standby:
            return experiment.measuresAngle ? "Make sure your iPhone's camera is facing the front of the cart." : "Lay it flat, with its top edge pointing at the centre of the turntable."
        case .countdown:
            return experiment.measuresAngle ? "Hold the cart still. Release it when the countdown ends and recording begins." : "Keep the turntable still. Spin it when the countdown ends and recording begins."
        case .measuring:
            return experiment.measuresAngle ? "Accelab is recording the motion of your cart as it travels down the track." : "Accelab is recording the spin of your turntable. Let it slow down, and tap Done once it has stopped."
        case .completed:
            return "Your lab data is ready for analysis! It's saved in Past Runs."
        }
    }
}
