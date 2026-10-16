//
//  SavedRun.swift
//  Accelab
//

import Foundation
import SwiftData

/// A finished run, kept after its method screen has been reset.
@Model
final class SavedRun {
    var date: Date
    /// `nil` until the user names the run.
    var name: String?
    var methodRawValue: String
    /// What a camera or a sensor run measured. `nil` for the runs saved before there was a choice. Optional,
    /// like `heights`, so that those runs still open.
    var experimentRawValue: String?
    /// `nil` when the angle steps were skipped, and for a projectile run, which has none.
    var desiredAngle: Double?
    var capturedAngle: Double?
    // The samples as plain arrays, so `DistanceSplit` and `PositionSplit` stay free of persistence.
    var times: [Double]
    /// The distance along the track, or a projectile's or a circle run's x.
    var displacements: [Double]
    /// A projectile's or a circle run's y, one for each of `displacements`. `nil` for a run along a track.
    /// Optional, and added without changing the properties above, so runs saved before projectile runs existed still open.
    var heights: [Double]?
    /// A turntable run's angular velocity, one for each of `times`. `nil` for every other kind of run.
    /// Optional, and added without changing the properties above, so older stores still open.
    var angularVelocities: [Double]?
    /// A turntable run's centripetal acceleration, one for each of `times`. `nil` for every other kind of
    /// run. Optional, so older stores still open.
    var centripetalAccelerations: [Double]?
    /// A turntable run's tangential acceleration, one for each of `times`. `nil` for every other kind of
    /// run. Optional, so older stores still open.
    var tangentialAccelerations: [Double]?
    /// A circle run's angle about the centre, one for each of `times`; its x and y are in `displacements`
    /// and `heights`, as a projectile's are. `nil` for every other kind of run. Optional, so older stores still open.
    var angles: [Double]?
    /// A circle run's distance from the centre, one for each of `times`. `nil` for every other kind of
    /// run. Optional, so older stores still open.
    var radii: [Double]?
    // Copied from the last sample, so a list row doesn't have to load the arrays.
    var duration: Double
    /// The run's headline length: the distance along the track, a projectile's final x, or a circle
    /// run's radius.
    var distance: Double
    var splitCount: Int
    /// A turntable run's fastest spin, copied from `angularVelocities` so a list row doesn't have to load
    /// them. `nil` for every other kind of run. Optional, so older stores still open.
    var peakAngularVelocity: Double?
    /// The JPEG of the tracked points, for a run filmed with the camera. The bytes rather than a file URL:
    /// the exported file lives in the temporary directory and goes when the run is reset.
    @Attribute(.externalStorage) var photo: Data?

    init(method: Method, experiment: CameraExperiment? = nil, sensorExperiment: SensorExperiment? = nil, date: Date = .now, desiredAngle: Double?, capturedAngle: Double?, data: RunData) {
        self.date = date
        self.name = nil
        self.methodRawValue = method.rawValue
        self.experimentRawValue = experiment?.rawValue ?? sensorExperiment?.rawValue
        self.desiredAngle = desiredAngle
        self.capturedAngle = capturedAngle
        self.times = []
        self.displacements = []
        self.heights = nil
        self.angularVelocities = nil
        self.centripetalAccelerations = nil
        self.tangentialAccelerations = nil
        self.angles = nil
        self.radii = nil
        self.duration = 0
        self.distance = 0
        self.splitCount = 0
        self.peakAngularVelocity = nil
        self.photo = nil
        update(data: data)
    }

    var method: Method {
        Method(rawValue: methodRawValue) ?? .camera
    }

    /// What a camera run filmed. `nil` for a sensor run, which has no such choice. A camera run saved
    /// before there was one filmed a cart on a track, so it counts as that.
    var experiment: CameraExperiment? {
        guard method == .camera else { return nil }
        return experimentRawValue.flatMap(CameraExperiment.init(rawValue:)) ?? .airTrack
    }

    /// `true` for a projectile run, whose samples are x and y rather than distance along a track.
    var isProjectile: Bool {
        experiment == .projectile
    }

    /// `true` for a run filmed going round a circle, whose samples are x, y and angle about its centre.
    var isCircle: Bool {
        experiment == .circularMotion
    }

    /// What a sensor run measured. `nil` for a camera run, which has no such choice. A sensor run saved
    /// before there was one was strapped to a cart on a track, so it counts as that.
    var sensorExperiment: SensorExperiment? {
        guard method == .sensor else { return nil }
        return experimentRawValue.flatMap(SensorExperiment.init(rawValue:)) ?? .airTrack
    }

    /// `true` for a turntable run, whose samples are angular velocity and accelerations rather than a distance.
    var isRotation: Bool {
        sensorExperiment == .circularMotion
    }

    /// The name the user gave the run, or the one it has until then.
    var title: String {
        name ?? defaultTitle
    }

    /// A name made from the run's method. What a camera run filmed is not part of it: that is a choice
    /// inside the method, shown beside the name in `caption`, where renaming the run leaves it in place.
    var defaultTitle: String {
        "\(method.rawValue) Run"
    }

    /// What goes under the run's name: what the run measured, then when the run was made.
    var caption: String {
        let dateText = date.formatted(date: .abbreviated, time: .shortened)
        guard let experimentName = experiment?.rawValue ?? sensorExperiment?.rawValue else { return dateText }
        return "\(experimentName) · \(dateText)"
    }

    /// Rebuilds the samples. Each call gives them new ids, so keep the result rather than calling this from a view's body.
    func makeData() -> RunData {
        if let angularVelocities, let centripetalAccelerations, let tangentialAccelerations {
            return .rotation(zip(times, zip(angularVelocities, zip(centripetalAccelerations, tangentialAccelerations))).map { RotationSplit(timeElapsed: $0, angularVelocity: $1.0, centripetalAcceleration: $1.1.0, tangentialAcceleration: $1.1.1) })
        } else if let heights, let angles, let radii {
            // Before `heights` alone: a circle run has heights too.
            return .circle(zip(times, zip(displacements, zip(heights, zip(angles, radii)))).map { CircleSplit(timeElapsed: $0, x: $1.0, y: $1.1.0, angle: $1.1.1.0, radius: $1.1.1.1) })
        } else if let heights {
            return .position(zip(times, zip(displacements, heights)).map { PositionSplit(timeElapsed: $0, x: $1.0, y: $1.1) })
        } else {
            return .distance(zip(times, displacements).map { DistanceSplit(timeElapsed: $0, displacement: $1) })
        }
    }

    func update(data: RunData) {
        switch data {
        case .distance(let splits):
            self.times = splits.map(\.timeElapsed)
            self.displacements = splits.map(\.displacement)
            self.heights = nil
            self.angularVelocities = nil
            self.centripetalAccelerations = nil
            self.tangentialAccelerations = nil
            self.angles = nil
            self.radii = nil
            self.peakAngularVelocity = nil
            self.distance = displacements.last ?? 0
        case .position(let splits):
            self.times = splits.map(\.timeElapsed)
            self.displacements = splits.map(\.x)
            self.heights = splits.map(\.y)
            self.angularVelocities = nil
            self.centripetalAccelerations = nil
            self.tangentialAccelerations = nil
            self.angles = nil
            self.radii = nil
            self.peakAngularVelocity = nil
            self.distance = displacements.last ?? 0
        case .rotation(let splits):
            self.times = splits.map(\.timeElapsed)
            self.displacements = []
            self.heights = nil
            self.angularVelocities = splits.map(\.angularVelocity)
            self.centripetalAccelerations = splits.map(\.centripetalAcceleration)
            self.tangentialAccelerations = splits.map(\.tangentialAcceleration)
            self.angles = nil
            self.radii = nil
            self.peakAngularVelocity = splits.map(\.angularVelocity).max()
            self.distance = 0
        case .circle(let splits):
            self.times = splits.map(\.timeElapsed)
            self.displacements = splits.map(\.x)
            self.heights = splits.map(\.y)
            self.angularVelocities = nil
            self.centripetalAccelerations = nil
            self.tangentialAccelerations = nil
            self.angles = splits.map(\.angle)
            self.radii = splits.map(\.radius)
            self.peakAngularVelocity = nil
            // The radius is the length that says what the run was, as a projectile's final x does.
            self.distance = splits.fittedRadius
        }

        self.duration = data.duration
        self.splitCount = data.count
    }
}
