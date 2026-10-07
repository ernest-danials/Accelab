//
//  TrackGeometry.swift
//  Accelab
//

import CoreGraphics
import Foundation

/// Turns the tracked positions on the clip into samples in metres and seconds: distance along the track
/// for a cart, x and y for a projectile.
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

    /// Turns a projectile's positions on the clip into its x and y against time, with the first point as
    /// the origin. Unlike a cart, a projectile follows no line to fit, so the axes are the picture's own:
    /// x along its width and y up its height, which is true to life only if the camera was held level.
    ///
    /// - Parameters:
    ///   - points: The projectile's position on each tracked frame, in any order.
    ///   - seconds: Gives the time of a frame from its index.
    static func makePositionSplits(from points: [TrackedPoint], calibration: CameraCalibration, seconds: (Int) -> TimeInterval) -> [PositionSplit] {
        let points = points.sorted { $0.frameIndex < $1.frameIndex }
        guard let first = points.first else { return [] }

        let sign = horizontalDirection(of: points)
        let startTime = seconds(first.frameIndex)

        return points.map { point in
            // Height is not given a sign from the motion: up is up wherever the projectile lands, and the
            // picture's y runs downwards.
            PositionSplit(timeElapsed: seconds(point.frameIndex) - startTime, x: sign * (point.position.x - first.position.x) * calibration.metersPerPixel, y: (first.position.y - point.position.y) * calibration.metersPerPixel)
        }
    }

    /// Which way along the picture a projectile's x counts up: 1 towards the right, -1 towards the left.
    /// Horizontal distance counts in the direction of travel, as the distance along a track does, so it
    /// is the side the last point lies on from the first.
    ///
    /// - Parameter points: The projectile's position on each tracked frame, in any order.
    static func horizontalDirection(of points: [TrackedPoint]) -> Double {
        guard let first = points.min(by: { $0.frameIndex < $1.frameIndex }), let last = points.max(by: { $0.frameIndex < $1.frameIndex }) else { return 1 }
        return last.position.x < first.position.x ? -1 : 1
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
