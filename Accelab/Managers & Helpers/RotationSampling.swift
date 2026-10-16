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

    /// The accelerometer's reading in the plane of the phone while the turntable stands still: its own
    /// offset, which can be a few hundredths of a g. A tilt of the turntable is not removed by this: its
    /// leak of gravity is fixed to the room, so it goes round in the phone's frame once per turn and
    /// averages out over whole turns instead.
    struct Bias: Sendable {
        var x: Double = 0
        var y: Double = 0
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

    /// The accelerometer's offset, as the median of each axis rather than the mean: the countdown's
    /// haptic ticks land in this window, and a median shrugs off their transients.
    static func makeBias(from readings: [Reading]) -> Bias {
        guard !readings.isEmpty else { return Bias() }
        return Bias(x: median(of: readings.map(\.accelerationX)), y: median(of: readings.map(\.accelerationY)))
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
}
