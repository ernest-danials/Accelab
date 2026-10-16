//
//  RotationSampling.swift
//  Accelab
//

import Foundation

/// The maths that turns the raw readings of a phone on a turntable into `RotationSplit`s. Pure (Foundation
/// only, no CoreMotion), so it can be compiled with `swiftc` beside a `main.swift` of numeric checks, which
/// is the only way to check it without a turntable: the Simulator has no sensors.
///
/// The phone lies flat on the turntable with its top edge pointing at the centre. So the centre is along
/// the phone's +y axis, the direction of travel is along ±x, and the turntable's axis is the phone's z.
///
/// Two things sit in the accelerometer's x and y besides the motion, and they are removed differently:
/// - The sensor's own offset, fixed in the phone's frame. `makeBias` takes it as the median of the
///   readings while the turntable stands still (the countdown).
/// - A turntable that isn't level leaks a little of gravity, g·sin(tilt), into the plane. That leak is
///   fixed to the *room*, so in the phone's frame it goes round once per turn: with φ the phone's angle
///   since it stood still, the leak in each channel is A·cos φ + B·sin φ. The rest median captures it at
///   φ = 0 (A, plus whatever is fixed), so subtracting the median alone would freeze the leak's rest value
///   in as a constant offset for the whole run, up to g·sin(tilt) (0.17 m/s² at 1°), which is the size
///   of a real tangential acceleration. It does *not* average out over whole turns once the median is
///   subtracted. So `makeSplits` integrates the gyroscope for φ, fits A and B to each channel by least
///   squares over the whole recording (`fitLeak`), and subtracts the leak's *change since rest*,
///   A·(cos φ − 1) + B·sin φ, on top of the rest median. The fit needs the whole recording, so the final
///   splits are made at the end; the live ones use the rest median alone.
nonisolated enum RotationSampling {
    /// One device-motion update, in the phone's own axes.
    struct Reading: Sendable {
        let timestamp: TimeInterval
        /// The gyroscope's rate about the phone's z axis, in rad/s.
        let rotationRateZ: Double
        /// The accelerometer's reading along x and y, in g, with gravity still in it, as CoreMotion reports
        /// it: opposite in sign to the acceleration itself (see `centripetalSign`). Lying flat, gravity is
        /// along z, so what is left in x and y is the motion, the sensor's own offset (which `bias`
        /// removes) and, if the turntable isn't level, a little of g that turns with the phone.
        let accelerationX: Double
        let accelerationY: Double
    }

    /// What the sensors read while the turntable stands still: the accelerometer's own offset in the plane
    /// of the phone, which can be a few hundredths of a g, and the gyroscope's. If the turntable isn't
    /// level the accelerometer's part also holds the gravity leak at the rest orientation; `fitLeak`
    /// accounts for that, so the two are subtracted together.
    struct Bias: Sendable {
        var x: Double = 0
        var y: Double = 0
        /// The gyroscope's reading at rest, in rad/s. Only used to keep the integrated angle from drifting;
        /// the reported angular velocity is the raw reading.
        var rotationRateZ: Double = 0
    }

    /// The gravity leak of a tilted turntable as it goes round in the phone's frame: in each channel
    /// `cos · cos φ + sin · sin φ`, in g, with φ the phone's angle since it stood still (see `phases`).
    struct Leak: Sendable {
        var xCos: Double = 0
        var xSin: Double = 0
        var yCos: Double = 0
        var ySin: Double = 0

        /// The leak's size, g·sin(tilt), in g, from the channel it was fitted on.
        var amplitude: Double { (xCos * xCos + xSin * xSin).squareRoot() }
    }

    /// Standard gravity, to turn the accelerometer's g into m/s².
    static let g0 = 9.80665

    // CoreMotion reports acceleration the other way round from the acceleration itself: a phone at rest
    // face up reads −1 g along z, and `MotionMeasuringManager` negates `userAcceleration.y` to get the
    // cart's acceleration down the track, which was settled on a device. So the centre, which is along
    // the phone's +y when the top edge points at it, reads as a negative y, and so does speeding up
    // along +x. The two signs are here, in one place, for the device test to confirm or flip.
    /// Makes the acceleration towards the centre positive.
    static let centripetalSign: Double = -1
    /// Makes the acceleration along the spin positive when `rotationRateZ` is positive.
    static let tangentialSign: Double = -1

    /// The sensors' offset, as the median of each axis rather than the mean: the countdown's haptic ticks
    /// land in this window, and a median shrugs off their transients.
    static func makeBias(from readings: [Reading]) -> Bias {
        guard !readings.isEmpty else { return Bias() }
        return Bias(x: median(of: readings.map(\.accelerationX)), y: median(of: readings.map(\.accelerationY)), rotationRateZ: median(of: readings.map(\.rotationRateZ)))
    }

    static func median(of values: [Double]) -> Double {
        let sorted = values.sorted()
        let middle = sorted.count / 2
        return sorted.count % 2 == 0 ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
    }

    /// What one reading says, before averaging: the angular speed, and the acceleration towards the centre
    /// and along the spin, in m/s².
    static func quantities(of reading: Reading, bias: Bias) -> (angularVelocity: Double, centripetal: Double, tangential: Double) {
        let angularVelocity = abs(reading.rotationRateZ)
        let centripetal = centripetalSign * (reading.accelerationY - bias.y) * g0
        // Signed by the spin, so that speeding up is positive whichever way the turntable was spun.
        let spinDirection: Double = reading.rotationRateZ < 0 ? -1 : 1
        let tangential = tangentialSign * spinDirection * (reading.accelerationX - bias.x) * g0
        return (angularVelocity, centripetal, tangential)
    }

    /// Averages readings into one `RotationSplit` per bin of `1 / sampleHz` seconds, timed from `startTime`.
    /// A bin's time is the mean of its readings' times, so a bin cut short by the end of the run still
    /// says when it was.
    struct Binner: Sendable {
        let startTime: TimeInterval
        let sampleHz: Double
        let bias: Bias

        private var binIndex: Int? = nil
        private var count = 0
        private var timeSum = 0.0
        private var angularVelocitySum = 0.0
        private var centripetalSum = 0.0
        private var tangentialSum = 0.0

        init(startTime: TimeInterval, sampleHz: Double, bias: Bias) {
            self.startTime = startTime
            self.sampleHz = sampleHz
            self.bias = bias
        }

        /// Adds a reading, and gives back the previous bin's split when this reading starts a new bin.
        mutating func add(_ reading: Reading) -> RotationSplit? {
            let elapsed = max(0, reading.timestamp - startTime)
            let index = Int(elapsed * sampleHz)
            var finished: RotationSplit? = nil

            if let binIndex, index != binIndex {
                finished = flush()
            }
            self.binIndex = index

            let values = RotationSampling.quantities(of: reading, bias: bias)
            count += 1
            timeSum += elapsed
            angularVelocitySum += values.angularVelocity
            centripetalSum += values.centripetal
            tangentialSum += values.tangential

            return finished
        }

        /// The bin being filled, as a split, and starts afresh. `nil` if it is empty.
        mutating func flush() -> RotationSplit? {
            guard count > 0 else { return nil }
            let n = Double(count)
            let split = RotationSplit(timeElapsed: timeSum / n, angularVelocity: angularVelocitySum / n, centripetalAcceleration: centripetalSum / n, tangentialAcceleration: tangentialSum / n)
            count = 0
            timeSum = 0
            angularVelocitySum = 0
            centripetalSum = 0
            tangentialSum = 0
            return split
        }
    }

    // MARK: - The whole recording

    /// The phone's angle at each reading, in rad, integrated (trapezoidally) from the gyroscope with its
    /// rest reading taken off, starting from 0 at the first reading, which is taken to be at the rest
    /// orientation. Signed by the spin, as a rotation about the phone's +z.
    static func phases(of readings: [Reading], bias: Bias) -> [Double] {
        var phases: [Double] = []
        phases.reserveCapacity(readings.count)
        var phase = 0.0
        for (index, reading) in readings.enumerated() {
            if index > 0 {
                let previous = readings[index - 1]
                let dt = max(0, reading.timestamp - previous.timestamp)
                phase += dt * ((previous.rotationRateZ - bias.rotationRateZ) + (reading.rotationRateZ - bias.rotationRateZ)) / 2
            }
            phases.append(phase)
        }
        return phases
    }

    /// How many whole turns the phone must make before the leak can be told from the fixed offset and
    /// from the motion. With fewer the recording is left with the rest median alone.
    static let minimumTurnsForLeakFit = 2.0

    /// The window over which the gyroscope is differenced for the angular acceleration regressor of the
    /// leak fit, in seconds, so that the gyroscope's noise doesn't swamp the real changes of speed.
    static let angularAccelerationWindow: TimeInterval = 0.5

    /// The angular acceleration at each reading, in rad/s², as the gyroscope's change across
    /// `angularAccelerationWindow` centred on the reading (clipped at the ends of the recording).
    static func angularAccelerations(of readings: [Reading]) -> [Double] {
        guard readings.count > 1 else { return readings.map { _ in 0 } }
        var result: [Double] = []
        result.reserveCapacity(readings.count)
        var lower = 0, upper = 0
        for (index, reading) in readings.enumerated() {
            while readings[lower].timestamp < reading.timestamp - angularAccelerationWindow / 2 { lower += 1 }
            while upper + 1 < readings.count && readings[upper + 1].timestamp <= reading.timestamp + angularAccelerationWindow / 2 { upper += 1 }
            let dt = readings[upper].timestamp - readings[lower].timestamp
            let (lowerIndex, upperIndex) = dt > 0 ? (lower, upper) : (max(0, index - 1), min(readings.count - 1, index + 1))
            let span = readings[upperIndex].timestamp - readings[lowerIndex].timestamp
            result.append(span > 0 ? (readings[upperIndex].rotationRateZ - readings[lowerIndex].rotationRateZ) / span : 0)
        }
        return result
    }

    /// Fits the gravity leak of a tilted turntable to a recording: each channel by least squares against
    /// `cos φ` and `sin φ`, with a constant term to take the fixed offset and a term for the motion that
    /// channel carries, so the motion can't lean on the sinusoids while the speed changes: ω² for y (the
    /// centripetal acceleration) and dω/dt for x (the tangential). The two channels are fitted on their
    /// own rather than one derived from the other, so nothing rests on the frame's handedness. `nil` when
    /// the phone turned less than `minimumTurnsForLeakFit`, or the equations are degenerate.
    static func fitLeak(readings: [Reading], phases: [Double]) -> Leak? {
        guard readings.count == phases.count, let first = phases.first, let last = phases.last else { return nil }
        guard abs(last - first) >= minimumTurnsForLeakFit * 2 * .pi else { return nil }

        let angularAccelerations = angularAccelerations(of: readings)
        var xRows: [(regressors: [Double], value: Double)] = []
        var yRows: [(regressors: [Double], value: Double)] = []
        for (index, reading) in readings.enumerated() {
            let phase = phases[index]
            xRows.append(([1, angularAccelerations[index], cos(phase), sin(phase)], reading.accelerationX))
            yRows.append(([1, reading.rotationRateZ * reading.rotationRateZ, cos(phase), sin(phase)], reading.accelerationY))
        }
        guard let x = leastSquares(xRows), let y = leastSquares(yRows) else { return nil }
        return Leak(xCos: x[2], xSin: x[3], yCos: y[2], ySin: y[3])
    }

    /// The readings with the leak's change since rest, `cos · (cos φ − 1) + sin · sin φ`, taken off each
    /// channel, so that the rest median still removes what was there at φ = 0.
    static func removingLeak(_ leak: Leak, from readings: [Reading], phases: [Double]) -> [Reading] {
        zip(readings, phases).map { reading, phase in
            let x = reading.accelerationX - (leak.xCos * (cos(phase) - 1) + leak.xSin * sin(phase))
            let y = reading.accelerationY - (leak.yCos * (cos(phase) - 1) + leak.ySin * sin(phase))
            return Reading(timestamp: reading.timestamp, rotationRateZ: reading.rotationRateZ, accelerationX: x, accelerationY: y)
        }
    }

    /// The splits of a whole recording: the leak of a tilted turntable fitted and taken off (when the
    /// phone turned enough for the fit), the rest bias subtracted, and the readings binned at `sampleHz`
    /// from `startTime`. Also gives back the leak, for whoever wants to know how level the table was.
    static func makeSplits(from readings: [Reading], bias: Bias, startTime: TimeInterval, sampleHz: Double) -> (splits: [RotationSplit], leak: Leak?) {
        let phases = phases(of: readings, bias: bias)
        let leak = fitLeak(readings: readings, phases: phases)
        let corrected = leak.map { removingLeak($0, from: readings, phases: phases) } ?? readings

        var binner = Binner(startTime: startTime, sampleHz: sampleHz, bias: bias)
        var splits: [RotationSplit] = []
        for reading in corrected {
            if let split = binner.add(reading) { splits.append(split) }
        }
        if let split = binner.flush() { splits.append(split) }
        return (splits, leak)
    }

    /// Ordinary least squares: the coefficients that best fit `value ≈ Σ coefficient·regressor` over the
    /// rows, through the normal equations. `nil` when they are degenerate.
    static func leastSquares(_ rows: [(regressors: [Double], value: Double)]) -> [Double]? {
        guard let size = rows.first?.regressors.count, size > 0 else { return nil }
        var matrix = Array(repeating: Array(repeating: 0.0, count: size), count: size)
        var constants = Array(repeating: 0.0, count: size)
        for row in rows {
            for i in 0..<size {
                constants[i] += row.regressors[i] * row.value
                for j in 0..<size { matrix[i][j] += row.regressors[i] * row.regressors[j] }
            }
        }
        return solve(rows: matrix, constants: constants)
    }

    /// Solves `size` linear equations in `size` unknowns by elimination with pivoting. `nil` when they
    /// are (nearly) dependent, judged against the equations' own scale.
    static func solve(rows: [[Double]], constants: [Double]) -> [Double]? {
        let size = constants.count
        var matrix = zip(rows, constants).map { $0 + [$1] }
        let scale = rows.flatMap { $0 }.map(abs).max() ?? 0
        guard scale > 0 else { return nil }

        for column in 0..<size {
            guard let pivotRow = (column..<size).max(by: { abs(matrix[$0][column]) < abs(matrix[$1][column]) }) else { return nil }
            matrix.swapAt(column, pivotRow)
            let pivot = matrix[column][column]
            guard abs(pivot) > scale * 1e-12 else { return nil }
            for row in 0..<size where row != column {
                let factor = matrix[row][column] / pivot
                guard factor != 0 else { continue }
                for k in column...size { matrix[row][k] -= factor * matrix[column][k] }
            }
        }
        return (0..<size).map { matrix[$0][size] / matrix[$0][$0] }
    }
}
