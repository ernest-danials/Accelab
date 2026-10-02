//
//  DistanceSplit.swift
//  Accelab
//

import Foundation

/// One distance–time sample of a run, independent of how it was measured.
struct DistanceSplit: Identifiable, Hashable, Sendable {
    let id = UUID()
    let timeElapsed: TimeInterval   // seconds since start
    let displacement: Double         // meters (displacement along track, + down-slope)
}
