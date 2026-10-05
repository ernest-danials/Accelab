//
//  VideoScrubBar.swift
//  Accelab
//

import SwiftUI

/// Moves through the kept part of a clip one frame at a time or by dragging.
struct VideoScrubBar: View {
    let scrubber: VideoScrubber

    var body: some View {
        HStack(spacing: 6) {
            stepButton(systemImage: "chevron.backward", byFrames: -1)

            Slider(value: Binding(get: { Double(scrubber.currentFrameIndex) }, set: { scrubber.seek(toFrame: Int($0.rounded())) }), in: Double(scrubber.trimRange.lowerBound)...Double(max(scrubber.trimRange.upperBound, scrubber.trimRange.lowerBound + 1))) {
                Text("Frame")
            }

            stepButton(systemImage: "chevron.forward", byFrames: 1)

            Text("\(scrubber.currentTime, specifier: "%.2f") s")
                .customFont(.subheadline, weight: .medium)
                .monospacedDigit()
                .frame(minWidth: 56, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .frame(height: GlassIconButton.height)
        .glassEffect(.regular, in: .capsule)
        .disabled(scrubber.frames == nil)
    }

    private func stepButton(systemImage: String, byFrames count: Int) -> some View {
        Button {
            scrubber.step(byFrames: count)
        } label: {
            Image(systemName: systemImage)
                .customFont(.subheadline, weight: .bold)
                .frame(width: 30, height: 30)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .buttonRepeatBehavior(.enabled)
        .accessibilityLabel(count < 0 ? "Previous Frame" : "Next Frame")
    }
}
