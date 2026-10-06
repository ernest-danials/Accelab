//
//  CameraCalibration.swift
//  Accelab
//

import CoreGraphics

/// A known length marked on a frame, which gives the scale of the video.
struct CameraCalibration: Hashable, Sendable {
    /// The ends of the known length, in pixels of the frame as it is shown.
    var start: CGPoint
    var end: CGPoint
    var lengthInMeters: Double

    var lengthInPixels: Double {
        hypot(end.x - start.x, end.y - start.y)
    }

    var metersPerPixel: Double {
        lengthInPixels > 0 ? lengthInMeters / lengthInPixels : 0
    }
}
