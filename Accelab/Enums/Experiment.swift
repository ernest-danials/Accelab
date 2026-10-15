//
//  Experiment.swift
//  Accelab
//

import Foundation

/// The lab being done, chosen first on the home screen. Each is done with one or both methods, chosen next;
/// the methods keep their own `CameraExperiment` and `SensorExperiment` for the steps that differ between them.
enum Experiment: String, CaseIterable, Identifiable {
    /// A cart down a sloped track.
    case airTrack = "Air Track"
    /// An object in flight.
    case projectile = "Projectile"
    /// Something going round in a circle.
    case circularMotion = "Circular Motion"

    var id: Self { self }

    /// The experiment as the camera method films it.
    var cameraExperiment: CameraExperiment {
        switch self {
        case .airTrack:
            return .airTrack
        case .projectile:
            return .projectile
        case .circularMotion:
            return .circularMotion
        }
    }

    /// The experiment as the sensor method measures it. `nil` for a projectile: the phone would have to fly.
    var sensorExperiment: SensorExperiment? {
        switch self {
        case .airTrack:
            return .airTrack
        case .projectile:
            return nil
        case .circularMotion:
            return .circularMotion
        }
    }

    func supports(_ method: Method) -> Bool {
        switch method {
        case .camera:
            return true
        case .sensor:
            return sensorExperiment != nil
        }
    }

    /// The method to steer people towards. Only where both methods give the same data: for a circle they
    /// measure different things, so the choice is the graph that is wanted.
    var recommendedMethod: Method? {
        switch self {
        case .airTrack:
            return .camera
        case .projectile, .circularMotion:
            return nil
        }
    }

    /// The experiment's symbol, which leads a saved run's row in Past Runs.
    var imageName: String {
        switch self {
        case .airTrack:
            return "angle"
        case .projectile:
            return "point.topleft.down.to.point.bottomright.curvepath"
        case .circularMotion:
            return "arrow.clockwise.circle"
        }
    }

    /// The name used in links (`accelab://circular-motion`).
    var slug: String {
        rawValue.lowercased().replacingOccurrences(of: " ", with: "-")
    }

    /// Shown under the app's name on the home screen while this experiment is chosen.
    var description: String {
        switch self {
        case .airTrack:
            return "A cart running down a sloped track: its distance along the track against time."
        case .projectile:
            return "An object in flight: its x and y position against time."
        case .circularMotion:
            return "Something going round in a circle: its angle, angular velocity or acceleration against time."
        }
    }

    /// Shown under the title of the screen where a method is chosen, saying how the methods' data differ.
    var methodChoiceHint: String {
        switch self {
        case .airTrack:
            return "Both methods give the cart's distance against time. Filming is the easier to set up."
        case .projectile:
            return "A projectile can only be filmed."
        case .circularMotion:
            return "The two methods measure different things. Choose by the graph you want to plot."
        }
    }

    // MARK: - Each method's card on the screen where a method is chosen

    /// What is done with the phone, in a sentence.
    func setup(for method: Method) -> String {
        switch (self, method) {
        case (.airTrack, .camera):
            return "Film the cart from the side as it runs down the track."
        case (.airTrack, .sensor):
            return "Strap your iPhone to the cart and let it ride down the track."
        case (.projectile, .camera):
            return "Film the object's flight from the side."
        case (.projectile, .sensor):
            return "Your iPhone would have to fly with the object, so a projectile can only be filmed."
        case (.circularMotion, .camera):
            return "Film a marker going round from straight above."
        case (.circularMotion, .sensor):
            return "Lay your iPhone flat on a turntable and spin it."
        }
    }

    /// The kind of data the method gives for this experiment, with no samples: what the card lists the
    /// columns of. `nil` where the method can't do the experiment.
    func emptyData(for method: Method) -> RunData? {
        switch (self, method) {
        case (.airTrack, _):
            return .distance([])
        case (.projectile, .camera):
            return .position([])
        case (.projectile, .sensor):
            return nil
        case (.circularMotion, .camera):
            return .circle([])
        case (.circularMotion, .sensor):
            return .rotation([])
        }
    }

    /// The graph the data is for, and what it gives. `nil` where the method can't do the experiment.
    func graph(for method: Method) -> ExperimentGraph? {
        switch (self, method) {
        case (.airTrack, _):
            return ExperimentGraph(y: "d", x: "t", shape: .parabola, note: "Fit d = ½at² for the acceleration.")
        case (.projectile, .camera):
            return ExperimentGraph(y: "y", x: "t", shape: .flight, note: "Fit y = v₀t − ½gt² for g.")
        case (.projectile, .sensor):
            return nil
        case (.circularMotion, .camera):
            return ExperimentGraph(y: "θ", x: "t", shape: .line, note: "The gradient is ω, and the period is 2π/ω.")
        case (.circularMotion, .sensor):
            return ExperimentGraph(y: "a", ySubscript: "c", x: "ω²", shape: .line, note: "The gradient is the radius.")
        }
    }
}

/// The graph students plot from a method's data, as shown on the screen where a method is chosen: y against x,
/// the shape the points should make, and what the graph gives.
struct ExperimentGraph {
    /// The shape the points should make.
    enum Shape {
        /// Starting flat and curving up, as distance does under a constant acceleration.
        case parabola
        /// Rising and falling, as a projectile's height does over the time of its flight.
        case flight
        /// Straight, through the origin.
        case line
    }

    let y: String
    /// Written small and lowered after `y`, as the c of a꜀.
    var ySubscript: String? = nil
    let x: String
    let shape: Shape
    let note: String
}
