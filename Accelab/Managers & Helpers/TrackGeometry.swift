//
//  TrackGeometry.swift
//  Accelab
//

import CoreGraphics
import Foundation

/// Turns the tracked positions on the clip into samples in metres and seconds: distance along the track
/// for a cart, x and y for a projectile, and x, y and angle about the centre for a marker going round.
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

    /// Turns a marker's positions on the clip into its x, y and angle against time, about the centre of
    /// the circle fitted through them. Putting the data in the circle's own frame is the analogue of the
    /// cart's fitted axis; the angle is unwrapped so it climbs through 2π, 4π, … (a sawtooth is the one
    /// thing a student can't undo in Desmos) and signed so it rises in the direction of travel, whichever
    /// way round the marker went. Empty when no circle fits the points (fewer than three, or all in a line).
    ///
    /// - Parameters:
    ///   - points: The marker's position on each tracked frame, in any order.
    ///   - seconds: Gives the time of a frame from its index.
    static func makeCircleSplits(from points: [TrackedPoint], calibration: CameraCalibration, seconds: (Int) -> TimeInterval) -> [CircleSplit] {
        let points = points.sorted { $0.frameIndex < $1.frameIndex }
        guard let first = points.first, let circle = fitCircle(through: points.map(\.position)) else { return [] }

        let scale = calibration.metersPerPixel
        // The picture's y runs downwards; the data's runs up, as a projectile's does.
        let positions = points.map { point in
            (x: (point.position.x - circle.center.x) * scale, y: (circle.center.y - point.position.y) * scale)
        }

        // Unwrapped first, then signed, then started from zero: each step relies on the one before.
        var angles: [Double] = []
        for position in positions {
            var angle = atan2(position.y, position.x)
            if let previous = angles.last {
                // A step of more than half a turn between two frames is a wrap, not the motion: at 60 fps
                // the marker would have to go round faster than 30 times a second for that to be wrong.
                let turns = ((angle - previous) / (2 * .pi)).rounded()
                angle -= turns * 2 * .pi
            }
            angles.append(angle)
        }
        let sign: Double = (angles.last ?? 0) < (angles.first ?? 0) ? -1 : 1
        let startAngle = angles.first ?? 0
        let startTime = seconds(first.frameIndex)

        return zip(points, zip(positions, angles)).map { point, sample in
            let (position, angle) = sample
            return CircleSplit(timeElapsed: seconds(point.frameIndex) - startTime, x: position.x, y: position.y, angle: sign * (angle - startAngle), radius: hypot(position.x, position.y))
        }
    }

    /// The circle that fits the points best, by least squares on the algebraic distance (Kåsa's fit):
    /// the D, E and F that minimise Σ (x² + y² + Dx + Ey + F)², from which the centre is (−D/2, −E/2) and
    /// the radius √(D²/4 + E²/4 − F). Three points define a circle; `nil` with fewer, or when they lie
    /// along a line, where no circle fits.
    static func fitCircle(through positions: [CGPoint]) -> (center: CGPoint, radius: Double)? {
        guard positions.count >= 3 else { return nil }

        // About the points' mean, so the sums that follow don't lose digits to the picture's size
        // (squared pixel positions run to millions where the offsets run to hundreds).
        let count = Double(positions.count)
        let meanX = positions.reduce(0) { $0 + $1.x } / count
        let meanY = positions.reduce(0) { $0 + $1.y } / count

        // The normal equations of the least-squares problem, with z = x² + y²:
        // [Σx²  Σxy  Σx] [D]   [−Σxz]
        // [Σxy  Σy²  Σy] [E] = [−Σyz]
        // [Σx   Σy   n ] [F]   [−Σz ]
        var sxx = 0.0, sxy = 0.0, syy = 0.0, sx = 0.0, sy = 0.0, sxz = 0.0, syz = 0.0, sz = 0.0
        for position in positions {
            let x = position.x - meanX
            let y = position.y - meanY
            let z = x * x + y * y
            sxx += x * x
            sxy += x * y
            syy += y * y
            sx += x
            sy += y
            sxz += x * z
            syz += y * z
            sz += z
        }

        guard let solution = solve(rows: [[sxx, sxy, sx], [sxy, syy, sy], [sx, sy, count]], constants: [-sxz, -syz, -sz]) else { return nil }
        let (d, e, f) = (solution[0], solution[1], solution[2])
        let radiusSquared = d * d / 4 + e * e / 4 - f
        guard radiusSquared > 0, radiusSquared.isFinite else { return nil }

        return (CGPoint(x: meanX - d / 2, y: meanY - e / 2), radiusSquared.squareRoot())
    }

    /// Solves three linear equations in three unknowns by elimination with pivoting. `nil` when they
    /// have no single solution.
    private static func solve(rows: [[Double]], constants: [Double]) -> [Double]? {
        var matrix = zip(rows, constants).map { $0 + [$1] }
        let size = rows.count
        // A pivot is judged against the equations' own scale, so a flat set of points is caught whatever its units.
        let scale = rows.flatMap { $0 }.reduce(0) { max($0, abs($1)) }

        for column in 0..<size {
            // The largest entry left in the column goes on the diagonal, which keeps the arithmetic sound.
            guard let pivotRow = (column..<size).max(by: { abs(matrix[$0][column]) < abs(matrix[$1][column]) }) else { return nil }
            matrix.swapAt(column, pivotRow)
            let pivot = matrix[column][column]
            guard abs(pivot) > scale * 1e-12 else { return nil }

            for row in 0..<size where row != column {
                let factor = matrix[row][column] / pivot
                for entry in column...size {
                    matrix[row][entry] -= factor * matrix[column][entry]
                }
            }
        }

        return (0..<size).map { matrix[$0][size] / matrix[$0][$0] }
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
