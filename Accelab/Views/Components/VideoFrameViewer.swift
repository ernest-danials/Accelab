//
//  VideoFrameViewer.swift
//  Accelab
//

import AVFoundation
import SwiftUI

/// A single frame of a clip with a scrubber, frame-step buttons, and pinch-to-zoom.
struct VideoFrameViewer: View {
    let scrubber: VideoScrubber

    @State private var zoom: CGFloat = 1
    @State private var zoomAtGestureStart: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var offsetAtGestureStart: CGSize = .zero

    private static let zoomRange: ClosedRange<CGFloat> = 1...6

    var body: some View {
        VStack(spacing: 10) {
            PlayerLayerView(player: scrubber.player)
                .scaleEffect(zoom)
                .offset(offset)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.black)
                .clipShape(.rect(cornerRadius: 16))
                .contentShape(.rect)
                .gesture(magnifyGesture.simultaneously(with: dragGesture))
                .onTapGesture(count: 2) {
                    withAnimation(.smooth) { resetZoom() }
                }

            HStack {
                stepButton(systemImage: "chevron.backward", byFrames: -1)

                Slider(value: Binding(get: { scrubber.currentTime }, set: { scrubber.seek(to: $0) }), in: 0...max(scrubber.duration, 0.01)) {
                    Text("Time")
                }

                stepButton(systemImage: "chevron.forward", byFrames: 1)

                Text("\(scrubber.currentTime, specifier: "%.2f") s")
                    .customFont(.subheadline, weight: .medium)
                    .monospacedDigit()
                    .frame(width: 70, alignment: .trailing)
            }
        }
    }

    private func stepButton(systemImage: String, byFrames count: Int) -> some View {
        Button {
            scrubber.step(byFrames: count)
        } label: {
            Image(systemName: systemImage)
                .customFont(.subheadline, weight: .medium)
                .padding(4)
        }
        .buttonStyle(.glass)
        .buttonRepeatBehavior(.enabled)
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                zoom = min(max(zoomAtGestureStart * value.magnification, Self.zoomRange.lowerBound), Self.zoomRange.upperBound)
            }
            .onEnded { _ in
                zoomAtGestureStart = zoom
                if zoom == Self.zoomRange.lowerBound {
                    withAnimation(.smooth) { resetZoom() }
                }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                // Panning only makes sense once zoomed in.
                guard zoom > Self.zoomRange.lowerBound else { return }
                offset = CGSize(width: offsetAtGestureStart.width + value.translation.width, height: offsetAtGestureStart.height + value.translation.height)
            }
            .onEnded { _ in
                offsetAtGestureStart = offset
            }
    }

    private func resetZoom() {
        zoom = 1
        zoomAtGestureStart = 1
        offset = .zero
        offsetAtGestureStart = .zero
    }
}

private struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.playerLayer.videoGravity = .resizeAspect
        view.playerLayer.player = player
        return view
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {
        uiView.playerLayer.player = player
    }

    final class PlayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }

        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}
