//
//  TrackGeometry.swift
//  Accelab
//

import CoreGraphics
import Foundation

/// Turns the cart's positions on the clip into distance–time samples.
enum TrackGeometry {
    /// - Parameters:
    ///   - points: The cart's position on each tracked frame, in any order.
    ///   - seconds: Gives the time of a frame from its index.
    static func makeSplits(from points: [TrackedPoint], calibration: CameraCalibration, seconds: (Int) -> TimeInterval) -> [DistanceSplit] {
        let points = points.sorted { $0.frameIndex < $1.frameIndex }
        guard let first = points.first, let last = points.last else { return [] }

        let axis = trackAxis(through: points.map(\.position))

        func position(alongAxis point: CGPoint) -> Double {
            (point.x - first.position.x) * axis.dx + (point.y - first.position.y) * axis.dy
        }

        // The cart starts from rest, so wherever it ends up is down-slope.
        let sign: Double = position(alongAxis: last.position) < 0 ? -1 : 1
        let startTime = seconds(first.frameIndex)

        return points.map { point in
            DistanceSplit(timeElapsed: seconds(point.frameIndex) - startTime, displacement: sign * position(alongAxis: point.position) * calibration.metersPerPixel)
        }
    }

    /// The direction of the best-fit straight line through the points, as a unit vector.
    static func trackAxis(through positions: [CGPoint]) -> CGVector {
        guard positions.count > 1 else { return CGVector(dx: 1, dy: 0) }

        let count = Double(positions.count)
        let meanX = positions.reduce(0) { $0 + $1.x } / count
        let meanY = positions.reduce(0) { $0 + $1.y } / count

        var sxx = 0.0, syy = 0.0, sxy = 0.0
        for position in positions {
            let dx = position.x - meanX
            let dy = position.y - meanY
            sxx += dx * dx
            syy += dy * dy
            sxy += dx * dy
        }

        // Principal axis of the scatter: the line that minimises the perpendicular distances.
        let angle = 0.5 * atan2(2 * sxy, sxx - syy)
        return CGVector(dx: cos(angle), dy: sin(angle))
    }
}
