//
//  PositionSplit.swift
//  Accelab
//

import Foundation

/// One position–time sample of a projectile, measured from where it started.
struct PositionSplit: Identifiable, Hashable, Sendable {
    let id = UUID()
    let timeElapsed: TimeInterval   // seconds since start
    let x: Double                    // meters (horizontal distance from the start, + in the direction of travel)
    let y: Double                    // meters (height above the start, + up)
}
