//
//  RunData.swift
//  Accelab
//

import Foundation

/// The samples of a run, whichever kind of motion it measured. Everything that shows, exports or saves
/// a run takes this, so the difference between the two kinds is handled in one place each.
enum RunData: Hashable, Sendable {
    /// Distance along a track against time.
    case distance([DistanceSplit])
    /// A projectile's x and y against time.
    case position([PositionSplit])

    var count: Int {
        switch self {
        case .distance(let splits):
            return splits.count
        case .position(let splits):
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
        }
    }
}
