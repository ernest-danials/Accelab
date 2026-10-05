//
//  Haptics.swift
//  Accelab
//

import UIKit

/// The app's haptic vocabulary. Played directly rather than through `sensoryFeedback`, so a tap still
/// gives feedback when its action replaces the view that was tapped.
enum Haptics {
    /// An ordinary button press.
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// The main action of a screen: continue, start, finish.
    static func prominentTap() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Something heavy starting or stopping, such as a recording.
    static func heavyTap() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    /// A value ticking over: a frame while scrubbing, a second of a countdown.
    static func tick() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
