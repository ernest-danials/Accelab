//
//  VideoScrubBar.swift
//  Accelab
//

import SwiftUI

/// Moves through the kept part of a clip one frame at a time or by dragging, and shows which frames
/// already have the cart marked on them.
struct VideoScrubBar: View {
    let scrubber: VideoScrubber
    /// Frames with a point on them, drawn along the bar.
    var markedFrames: [Int] = []
    /// Marked frames worth a second look, drawn in orange.
    var flaggedFrames: Set<Int> = []

    private static let coordinateSpace: NamedCoordinateSpace = .named("VideoScrubBar")
    private static let handleWidth: CGFloat = 14
    private static let barHeight: CGFloat = 32

    var body: some View {
        HStack(spacing: 6) {
            stepButton(systemImage: "chevron.backward", byFrames: -1)

            GeometryReader { geometry in
                let range = scrubber.trimRange
                let span = CGFloat(max(range.upperBound - range.lowerBound, 1))
                let usableWidth = max(geometry.size.width - Self.handleWidth, 1)
                let position: (Int) -> CGFloat = { frame in
                    Self.handleWidth / 2 + usableWidth * CGFloat(frame - range.lowerBound) / span
                }

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.primary.opacity(0.18))
                        .frame(height: 6)
                        .padding(.horizontal, Self.handleWidth / 2)

                    // One sliver per marked frame; neighbouring frames join into a band.
                    Canvas { context, size in
                        let width = max(usableWidth / span + 0.5, 2)
                        for frame in markedFrames where range.contains(frame) {
                            let rect = CGRect(x: position(frame) - width / 2, y: size.height / 2 - 5, width: width, height: 10)
                            context.fill(Path(roundedRect: rect, cornerRadius: 1), with: .color(flaggedFrames.contains(frame) ? .orange : .yellow))
                        }
                    }
                    .allowsHitTesting(false)

                    Capsule()
                        .fill(.white)
                        .stroke(.black.opacity(0.25), lineWidth: 1)
                        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                        .frame(width: Self.handleWidth - 4, height: Self.barHeight - 6)
                        .frame(width: Self.handleWidth)
                        .offset(x: position(scrubber.currentFrameIndex) - Self.handleWidth / 2)
                        .allowsHitTesting(false)
                }
                .frame(height: Self.barHeight)
                .contentShape(.rect)
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: Self.coordinateSpace)
                        .onChanged { value in
                            let fraction = (value.location.x - Self.handleWidth / 2) / usableWidth
                            seek(toFrame: range.lowerBound + Int((fraction * span).rounded()))
                        }
                )
            }
            .frame(height: Self.barHeight)
            .coordinateSpace(Self.coordinateSpace)
            .accessibilityElement()
            .accessibilityLabel("Frame")
            .accessibilityValue("\(scrubber.currentTime, specifier: "%.2f") seconds")
            .accessibilityAdjustableAction { direction in
                scrubber.step(byFrames: direction == .increment ? 1 : -1)
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

    /// Moves to a frame, with a tick whenever the frame shown actually changes.
    private func seek(toFrame index: Int) {
        let previous = scrubber.currentFrameIndex
        scrubber.seek(toFrame: index)
        if scrubber.currentFrameIndex != previous { Haptics.tick() }
    }

    private func stepButton(systemImage: String, byFrames count: Int) -> some View {
        Button {
            seek(toFrame: scrubber.currentFrameIndex + count)
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
