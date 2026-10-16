//
//  MethodManager.swift
//  Accelab
//
//  Created by Myung Joon Kang on 2026-10-04.
//

import Observation
import SwiftUI

/// Which screen is open: the home screen, where the experiment is chosen, the one where a method is chosen
/// for it, or a method's own steps.
@Observable
@MainActor
final class MethodManager {
    enum Screen: Hashable {
        /// Choosing the experiment.
        case home
        /// Choosing the method for `experiment`.
        case methods
        /// A method's steps, for `experiment`.
        case method(Method)
    }

    private(set) var screen: Screen = .home
    /// Chosen on the home screen. Kept when going back to it, so it opens on the experiment it was left on,
    /// and unchanged while a method is open.
    var experiment: Experiment = .airTrack

    func show(_ screen: Screen) {
        withAnimation {
            self.screen = screen
        }
    }

    /// Opens what a deep link names: an experiment (`accelab://circular-motion`), where its method is
    /// chosen, or one of its methods (`accelab://circular-motion/sensor`). A link naming only a method
    /// (`accelab://camera`) dates from before experiments were chosen first, when it meant the air track.
    /// Ignored while a method is open, so a link can't pull a run out from under its screen.
    func open(_ url: URL) {
        guard url.scheme?.lowercased() == "accelab", screen == .home || screen == .methods, let host = url.host()?.lowercased() else { return }

        if let method = Method.allCases.first(where: { $0.slug == host }) {
            self.experiment = .airTrack
            show(.method(method))
            return
        }

        guard let experiment = Experiment.allCases.first(where: { $0.slug == host }) else { return }
        self.experiment = experiment

        let methodName = url.pathComponents.first { $0 != "/" }?.lowercased()
        if let method = Method.allCases.first(where: { $0.slug == methodName }), experiment.supports(method) {
            show(.method(method))
        } else {
            show(.methods)
        }
    }
}
