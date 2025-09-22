//
//  Step.swift
//  Accelab
//
//  Created by Myung Joon Kang on 2025-09-21.
//

import Foundation

enum Step: CaseIterable, Identifiable {
    case idle, chooseAngle, determineAngle, standby, measuring, completed
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .idle:
            return "Accelab"
        case .chooseAngle:
            return "Choose the Angle"
        case .determineAngle:
            return "Determine the Angle"
        case .standby:
            return "Attach Your iPhone to the Cart"
        case .measuring:
            return "Collect Data"
        case .completed:
            return "Completed"
        }
    }
    
    var subtitle: String {
        switch self {
        case .idle:
            return "Welcome to"
        case .chooseAngle:
            return "Step 1"
        case .determineAngle:
            return "Step 2"
        case .standby:
            return "Step 3"
        case .measuring:
            return "Step 4"
        case .completed:
            return ""
        }
    }
    
    var description: String {
        switch self {
        case .idle:
            return ""
        case .chooseAngle:
            return "Choose the desired slope of your track."
        case .determineAngle:
            return "Measure and determine the slope of your track so it matches your desired slope."
        case .standby:
            return "Make sure your iPhone's camera is facing the front of the cart."
        case .measuring:
            return "Accelab is recording the motion of your cart as it travels down the track."
        case .completed:
            return "Your lab data is ready for analysis! Make sure to save it before exiting."
        }
    }
}
