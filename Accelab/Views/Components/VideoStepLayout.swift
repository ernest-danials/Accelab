//
//  VideoStepLayout.swift
//  Accelab
//

import SwiftUI

/// The controls of a step that floats over a full-screen video: the step's title in the top-leading
/// corner, the step's own controls beside it, and a row along the bottom. Laid out in rows rather than
/// positioned, so nothing overlaps on a smaller screen.
///
/// Tapping the video hides the controls, as in a video player. The top row goes entirely; each step
/// decides what in its bottom row is essential enough to stay. Hidden controls fade in place rather than
/// leaving the layout, so nothing slides when they return.
struct VideoStepLayout<TopTrailing: View, Bottom: View>: View {
    /// The method the step belongs to, which decides the step's number and wording.
    let method: Method
    let step: CameraMethodStep
    /// What to do right now, shown under the step's title. Defaults to the step's description.
    var instruction: LocalizedStringKey? = nil
    let isChromeHidden: Bool
    @ViewBuilder var topTrailing: TopTrailing
    @ViewBuilder var bottom: Bottom

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                titleCard

                Spacer(minLength: 0)

                // The step's controls keep their natural size; the title card gives way if space is short.
                topTrailing
                    .fixedSize()
            }
            .hiddenWithChrome(isChromeHidden)

            Spacer(minLength: 0)

            GlassEffectContainer {
                HStack(spacing: 10) {
                    bottom
                }
            }
        }
        .padding()
        // The rows are sized for ordinary text; much larger text wouldn't leave room for the video.
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
        // Dark glass with light text reads over any footage, whatever the app's appearance.
        .environment(\.colorScheme, .dark)
    }

    private var titleCard: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(step.subtitle(for: method)) · \(step.title(for: method))")
                .customFont(.subheadline, weight: .bold)

            Text(instruction ?? LocalizedStringKey(step.description(for: method)))
                .customFont(.caption, weight: .medium)
                .foregroundStyle(.primary.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.opacity)
        }
        .frame(maxWidth: 260, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }
}

extension EnvironmentValues {
    /// `true` on controls that are hidden with the rest. Glass controls read it and dissolve their own
    /// glass, because glass inside a `GlassEffectContainer` ignores the opacity of the view around it.
    @Entry var isHiddenWithChrome: Bool = false
}

extension View {
    /// Fades a control out with the rest of the controls, keeping its place in the layout.
    func hiddenWithChrome(_ isHidden: Bool) -> some View {
        self
            .opacity(isHidden ? 0 : 1)
            .environment(\.isHiddenWithChrome, isHidden)
            .allowsHitTesting(!isHidden)
            .accessibilityHidden(isHidden)
    }
}

/// A glass capsule, the same height as the buttons, for a short status shown beside them.
struct GlassStatusLabel<Content: View>: View {
    @ViewBuilder var content: Content

    @Environment(\.isHiddenWithChrome) private var isHiddenWithChrome

    var body: some View {
        content
            .customFont(.subheadline, weight: .semibold)
            .monospacedDigit()
            .lineLimit(1)
            .opacity(isHiddenWithChrome ? 0 : 1)
            .padding(.horizontal, 14)
            .frame(height: GlassIconButton.height)
            .glassEffect(isHiddenWithChrome ? .identity : .regular, in: .capsule)
    }
}
