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
    /// What a camera run filmed. `nil` for a sensor run, and for the camera runs saved before there was a
    /// choice. Optional, like `heights`, so that those runs still open.
    var experimentRawValue: String?
    /// `nil` when the angle steps were skipped, and for a projectile run, which has none.
    var desiredAngle: Double?
    var capturedAngle: Double?
    // The samples as plain arrays, so `DistanceSplit` and `PositionSplit` stay free of persistence.
    var times: [Double]
    /// The distance along the track, or a projectile's x.
    var displacements: [Double]
    /// A projectile's y, one for each of `displacements`. `nil` for a run along a track. Optional, and
    /// added without changing the properties above, so runs saved before projectile runs existed still open.
    var heights: [Double]?
    // Copied from the last sample, so a list row doesn't have to load the arrays.
    var duration: Double
    var distance: Double
    var splitCount: Int
    /// The JPEG of the tracked points, for a run filmed with the camera. The bytes rather than a file URL:
    /// the exported file lives in the temporary directory and goes when the run is reset.
    @Attribute(.externalStorage) var photo: Data?

    init(method: Method, experiment: CameraExperiment? = nil, date: Date = .now, desiredAngle: Double?, capturedAngle: Double?, data: RunData) {
        self.date = date
        self.name = nil
        self.methodRawValue = method.rawValue
        self.experimentRawValue = experiment?.rawValue
        self.desiredAngle = desiredAngle
        self.capturedAngle = capturedAngle
        self.times = []
        self.displacements = []
        self.heights = nil
        self.duration = 0
        self.distance = 0
        self.splitCount = 0
        self.photo = nil
        update(data: data)
    }

    var method: Method {
        Method(rawValue: methodRawValue) ?? .camera
    }

    /// `true` for a projectile run, whose samples are x and y rather than distance along a track.
    var isProjectile: Bool {
        experimentRawValue == CameraExperiment.projectile.rawValue
    }

    /// The name the user gave the run, or the one it has until then.
    var title: String {
        name ?? defaultTitle
    }

    /// A name made from the run's method, or from "Projectile" for a projectile run.
    var defaultTitle: String {
        "\(isProjectile ? CameraExperiment.projectile.rawValue : method.rawValue) Run"
    }

    /// The symbol a list shows the run with.
    var imageName: String {
        isProjectile ? CameraExperiment.projectile.imageName : method.imageName
    }

    /// Rebuilds the samples. Each call gives them new ids, so keep the result rather than calling this from a view's body.
    func makeData() -> RunData {
        if let heights {
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
        case .position(let splits):
            self.times = splits.map(\.timeElapsed)
            self.displacements = splits.map(\.x)
            self.heights = splits.map(\.y)
        }

        self.duration = data.duration
        self.distance = displacements.last ?? 0
        self.splitCount = data.count
    }
}
