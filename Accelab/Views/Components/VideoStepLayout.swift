//
//  VideoStepLayout.swift
//  Accelab
//

import SwiftUI

/// The controls of a step that floats over a full-screen video: the step's title in the top-leading
/// corner, the step's own controls beside it, and a row along the bottom. Laid out in rows rather than
/// positioned, so nothing overlaps on a smaller screen.
struct VideoStepLayout<TopTrailing: View, Bottom: View>: View {
    let step: CameraMethodStep
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
