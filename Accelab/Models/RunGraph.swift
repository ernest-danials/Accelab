//
//  RunGraph.swift
//  Accelab
//

import Foundation

/// A graph students can plot from a run, as the two columns it needs. The x column always comes before the
/// y column in the data, so an export of just these two is ready to plot: Desmos takes the first as x and the second as y.
struct RunGraph: Hashable {
    /// "θ against t", y first, as the graph is said.
    let title: String
    /// What the graph shows or gives, in a few words.
    let note: String
    /// Indices into `CSVExporter.columns(for:)`.
    let columns: Set<Int>

    /// The graphs for a run's data, the lab's own graph first (the one on the screen where a method is chosen).
    static func graphs(for data: RunData) -> [RunGraph] {
        switch data {
        case .distance:
            return [RunGraph(title: "d against t", note: "Fit d = ½at² for the acceleration.", columns: [0, 1])]
        case .position:
            return [
                RunGraph(title: "y against t", note: "Fit y = v₀t − ½gt² for g, with v₀ the upward launch speed.", columns: [0, 2]),
                RunGraph(title: "x against t", note: "The gradient is the horizontal velocity.", columns: [0, 1]),
                RunGraph(title: "y against x", note: "The path of the flight, a parabola.", columns: [1, 2]),
            ]
        case .rotation:
            return [
                RunGraph(title: "a against ω²", note: "The gradient is the radius. One cluster means a steady spin.",columns: [2, 3]),
                RunGraph(title: "ω against t", note: "The gradient is the angular acceleration.", columns: [0, 1]),
                RunGraph(title: "aₜ against t", note: "Zero while the spin is steady, positive while it speeds up.", columns: [0, 4]),
            ]
        case .circle:
            return [
                RunGraph(title: "θ against t", note: "The gradient is ω, and the period is 2π/ω.", columns: [0, 3]),
                RunGraph(title: "y against x", note: "The circle itself.", columns: [1, 2]),
                RunGraph(title: "x against t", note: "A sine wave, as in simple harmonic motion.", columns: [0, 1]),
                RunGraph(title: "r against t", note: "Flat if the radius stayed the same.", columns: [0, 4]),
            ]
        }
    }
}
