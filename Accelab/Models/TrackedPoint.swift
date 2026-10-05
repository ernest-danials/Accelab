//
//  TrackedPoint.swift
//  Accelab
//

import CoreGraphics

/// Where the cart is on one frame of the clip.
struct TrackedPoint: Identifiable, Hashable, Sendable {
    let frameIndex: Int
    /// In pixels of the frame as it is shown.
    var position: CGPoint
    /// `false` when the point came from automatic tracking.
    var isManual: Bool = true
    /// How sure automatic tracking was, from 0 to 1. Always 1 for manual points.
    var confidence: Double = 1

    var id: Int { frameIndex }
}
