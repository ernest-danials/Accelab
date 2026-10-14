//
//  RunData.swift
//  Accelab
//

import Foundation

/// The samples of a run, whichever kind of motion it measured. Everything that shows, exports or saves
/// a run takes this, so the difference between the kinds is handled in one place each.
enum RunData: Hashable, Sendable {
    /// Distance along a track against time.
    case distance([DistanceSplit])
    /// A projectile's x and y against time.
    case position([PositionSplit])
    /// A turntable's angular velocity and the acceleration on it against time.
    case rotation([RotationSplit])
    /// A marker going round a circle: its x, y and angle about the circle's centre against time.
    case circle([CircleSplit])

    var count: Int {
        switch self {
        case .distance(let splits):
            return splits.count
        case .position(let splits):
            return splits.count
        case .rotation(let splits):
            return splits.count
        case .circle(let splits):
            return splits.count
        }
    }

    var isEmpty: Bool { count == 0 }

    /// The time of the last sample.
    var duration: TimeInterval {
        switch self {
        case .distance(let splits):
            return splits.last?.timeElapsed ?? 0
        case .position(let splits):
            return splits.last?.timeElapsed ?? 0
        case .rotation(let splits):
            return splits.last?.timeElapsed ?? 0
        case .circle(let splits):
            return splits.last?.timeElapsed ?? 0
        }
    }
}
