//
//  CircleSplit.swift
//  Accelab
//

import Foundation

/// One sample of a marker going round a circle, measured about the centre of the circle fitted through
/// every tracked point.
struct CircleSplit: Identifiable, Hashable, Sendable {
    let id = UUID()
    let timeElapsed: TimeInterval   // seconds since start
    let x: Double                    // meters, from the centre of the circle (+ to the right of the picture)
    let y: Double                    // meters, from the centre of the circle (+ up the picture)
    let angle: Double                // radians about the centre, 0 at the first point, climbing through 2π, 4π… in the direction of travel
    let radius: Double               // meters, this point's distance from the centre
}

extension Array where Element == CircleSplit {
    /// The radius of the circle fitted through the samples: the root mean square of their distances
    /// from its centre, which is what the least-squares fit makes the radius come to (its condition on
    /// the constant term is that the squared distances average to the squared radius).
    var fittedRadius: Double {
        guard !isEmpty else { return 0 }
        return (reduce(0) { $0 + $1.radius * $1.radius } / Double(count)).squareRoot()
    }

    /// How many times round the marker went, from the angle at the last sample.
    var turns: Double {
        (last?.angle ?? 0) / (2 * .pi)
    }
}
