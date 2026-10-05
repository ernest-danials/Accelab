//
//  TrimStepView.swift
//  Accelab
//

import SwiftUI

struct TrimStepView: View {
    let scrubber: VideoScrubber
    let onBack: () -> Void
    let onContinue: () -> Void

    @State private var isChromeHidden: Bool = false

    var body: some View {
        ZStack {
            VideoFrameViewer(scrubber: scrubber, onTap: { _ in
                withAnimation(.smooth) { self.isChromeHidden.toggle() }
            }) { _ in
                EmptyView()
            }

            VideoStepLayout(step: .trim, isChromeHidden: isChromeHidden) {
                GlassStatusLabel {
                    Label("\(keptDuration, specifier: "%.2f") s", systemImage: "scissors")
                        .contentTransition(.numericText(value: keptDuration))
                }
                .accessibilityLabel("\(keptDuration, specifier: "%.2f") seconds kept")
            } bottom: {
                if !isChromeHidden {
                    GlassIconButton(systemImage: "chevron.backward", label: "Back", perform: onBack)
                        .transition(.blurReplace)
                }

                // The trim bar is what this step is for, so it stays when the rest is hidden.
                TrimRangeBar(scrubber: scrubber)

                if !isChromeHidden {
                    GlassIconButton(systemImage: "arrow.forward", label: "Continue", style: .prominent, isDisabled: scrubber.frames == nil, perform: onContinue)
                        .transition(.blurReplace)
                }
            }
        }
    }

    private var keptDuration: TimeInterval {
        scrubber.seconds(at: scrubber.trimRange.upperBound) - scrubber.seconds(at: scrubber.trimRange.lowerBound)
    }
}

/// The whole clip as a bar with a handle at each end of the part being kept. Moving a handle shows its frame.
private struct TrimRangeBar: View {
    let scrubber: VideoScrubber

    private static let coordinateSpace: NamedCoordinateSpace = .named("TrimRangeBar")
    private static let handleWidth: CGFloat = 18
    private static let height: CGFloat = 32

    var body: some View {
        HStack(spacing: 10) {
            timeLabel(for: scrubber.trimRange.lowerBound)

            GeometryReader { geometry in
                let usableWidth = max(geometry.size.width - Self.handleWidth, 1)
                let lastFrame = max(scrubber.frameCount - 1, 1)
                let startX = usableWidth * CGFloat(scrubber.trimRange.lowerBound) / CGFloat(lastFrame)
                let endX = usableWidth * CGFloat(scrubber.trimRange.upperBound) / CGFloat(lastFrame)

                let frameIndex: (CGFloat) -> Int = { x in
                    Int(((x - Self.handleWidth / 2) / usableWidth * CGFloat(lastFrame)).rounded())
                }

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.primary.opacity(0.15))
                        .frame(height: 6)
                        .padding(.horizontal, Self.handleWidth / 2)

                    Capsule()
                        .fill(Method.camera.color)
                        .frame(width: max(endX - startX, 0), height: 6)
                        .offset(x: startX + Self.handleWidth / 2)

                    handle
                        .offset(x: startX)
                        .gesture(DragGesture(minimumDistance: 0, coordinateSpace: Self.coordinateSpace).onChanged { scrubber.setTrimStart(frameIndex($0.location.x)) })
                        .accessibilityLabel("Start")

                    handle
                        .offset(x: endX)
                        .gesture(DragGesture(minimumDistance: 0, coordinateSpace: Self.coordinateSpace).onChanged { scrubber.setTrimEnd(frameIndex($0.location.x)) })
                        .accessibilityLabel("End")
                }
                .frame(height: Self.height)
            }
            .frame(height: Self.height)
            .coordinateSpace(Self.coordinateSpace)

            timeLabel(for: scrubber.trimRange.upperBound)
        }
        .padding(.horizontal, 14)
        .frame(height: GlassIconButton.height)
        .glassEffect(.regular, in: .capsule)
        .disabled(scrubber.frames == nil)
    }

    private var handle: some View {
        Capsule()
            .fill(.white)
            .stroke(.black.opacity(0.2), lineWidth: 1)
            .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
            .frame(width: Self.handleWidth - 6, height: Self.height - 6)
            .frame(width: Self.handleWidth, height: Self.height)
            // Wider than it looks, so it is easy to grab.
            .contentShape(.rect.inset(by: -10))
    }

    private func timeLabel(for frameIndex: Int) -> some View {
        Text("\(scrubber.seconds(at: frameIndex), specifier: "%.2f") s")
            .customFont(.subheadline, weight: .medium)
            .monospacedDigit()
            .frame(minWidth: 52)
    }
}
