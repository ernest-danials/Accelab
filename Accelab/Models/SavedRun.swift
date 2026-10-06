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
    /// `nil` when the angle steps were skipped.
    var desiredAngle: Double?
    var capturedAngle: Double?
    // The samples as two plain arrays, so `DistanceSplit` stays free of persistence.
    var times: [Double]
    var displacements: [Double]
    // Copied from the last sample, so a list row doesn't have to load the arrays.
    var duration: Double
    var distance: Double
    var splitCount: Int
    /// The JPEG of the tracked points, for a camera run. The bytes rather than a file URL: the exported
    /// file lives in the temporary directory and goes when the run is reset.
    @Attribute(.externalStorage) var photo: Data?

    init(method: Method, date: Date = .now, desiredAngle: Double?, capturedAngle: Double?, splits: [DistanceSplit]) {
        self.date = date
        self.name = nil
        self.methodRawValue = method.rawValue
        self.desiredAngle = desiredAngle
        self.capturedAngle = capturedAngle
        self.times = splits.map(\.timeElapsed)
        self.displacements = splits.map(\.displacement)
        self.duration = splits.last?.timeElapsed ?? 0
        self.distance = splits.last?.displacement ?? 0
        self.splitCount = splits.count
        self.photo = nil
    }

    var method: Method {
        Method(rawValue: methodRawValue) ?? .camera
    }

    /// The name the user gave the run, or one made from its method.
    var title: String {
        name ?? "\(method.rawValue) Run"
    }

    /// Rebuilds the samples. Each call gives them new ids, so keep the result rather than calling this from a view's body.
    func makeSplits() -> [DistanceSplit] {
        zip(times, displacements).map { DistanceSplit(timeElapsed: $0, displacement: $1) }
    }

    func update(splits: [DistanceSplit]) {
        self.times = splits.map(\.timeElapsed)
        self.displacements = splits.map(\.displacement)
        self.duration = splits.last?.timeElapsed ?? 0
        self.distance = splits.last?.displacement ?? 0
        self.splitCount = splits.count
    }
}
