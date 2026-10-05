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
/// decides what in its bottom row is essential enough to stay.
struct VideoStepLayout<TopTrailing: View, Bottom: View>: View {
    let step: CameraMethodStep
    let isChromeHidden: Bool
    @ViewBuilder var topTrailing: TopTrailing
    @ViewBuilder var bottom: Bottom

    var body: some View {
        VStack(spacing: 0) {
            if !isChromeHidden {
                HStack(alignment: .top, spacing: 12) {
                    titleCard

                    Spacer(minLength: 0)

                    // The step's controls keep their natural size; the title card gives way if space is short.
                    topTrailing
                        .fixedSize()
                }
                .transition(.blurReplace)
            }

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
            Text("\(step.subtitle) · \(step.title)")
                .customFont(.subheadline, weight: .bold)

            Text(step.description)
                .customFont(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: 250, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }
}

/// A glass capsule, the same height as the buttons, for a short status shown beside them.
struct GlassStatusLabel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .customFont(.subheadline, weight: .semibold)
            .monospacedDigit()
            .lineLimit(1)
            .padding(.horizontal, 14)
            .frame(height: GlassIconButton.height)
            .glassEffect(.regular, in: .capsule)
    }
}
