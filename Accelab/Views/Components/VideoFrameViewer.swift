//
//  VideoFrameViewer.swift
//  Accelab
//

import AVFoundation
import SwiftUI

/// Converts between points on the clip and points in the viewer, taking letterboxing, zoom and pan into account.
struct VideoViewMapping {
    static let coordinateSpace: NamedCoordinateSpace = .named("VideoFrameViewer")

    let videoSize: CGSize
    let containerSize: CGSize
    let zoom: CGFloat
    let offset: CGSize

    /// View points per video pixel when the frame fills the viewer, which is how it is shown at a zoom of 1.
    private var fillScale: CGFloat {
        guard videoSize.width > 0, videoSize.height > 0 else { return 1 }
        return max(containerSize.width / videoSize.width, containerSize.height / videoSize.height)
    }

    /// The zoom at which the whole frame just fits inside the viewer. Never more than 1.
    var fitZoom: CGFloat {
        guard videoSize.width > 0, videoSize.height > 0 else { return 1 }
        return min(containerSize.width / videoSize.width, containerSize.height / videoSize.height) / fillScale
    }

    private var center: CGPoint {
        CGPoint(x: containerSize.width / 2, y: containerSize.height / 2)
    }

    /// The size of the whole frame when it fills the viewer, before any zoom.
    var filledSize: CGSize {
        CGSize(width: videoSize.width * fillScale, height: videoSize.height * fillScale)
    }

    func viewPoint(for videoPoint: CGPoint) -> CGPoint {
        let fittedX = center.x + (videoPoint.x - videoSize.width / 2) * fillScale
        let fittedY = center.y + (videoPoint.y - videoSize.height / 2) * fillScale
        return CGPoint(x: center.x + (fittedX - center.x) * zoom + offset.width, y: center.y + (fittedY - center.y) * zoom + offset.height)
    }

    func videoPoint(for viewPoint: CGPoint) -> CGPoint {
        let fittedX = center.x + (viewPoint.x - offset.width - center.x) / zoom
        let fittedY = center.y + (viewPoint.y - offset.height - center.y) / zoom
        return CGPoint(x: videoSize.width / 2 + (fittedX - center.x) / fillScale, y: videoSize.height / 2 + (fittedY - center.y) / fillScale)
    }

    func contains(_ videoPoint: CGPoint) -> Bool {
        CGRect(origin: .zero, size: videoSize).contains(videoPoint)
    }

    func clamped(_ videoPoint: CGPoint) -> CGPoint {
        CGPoint(x: min(max(videoPoint.x, 0), videoSize.width), y: min(max(videoPoint.y, 0), videoSize.height))
    }
}

/// A single frame of a clip filling the whole screen, with pinch-to-zoom and panning. Whatever the fill
/// crops can be reached by panning, or by pinching out until the whole frame fits.
///
/// `overlay` is drawn over the frame at a constant size; use the mapping it is given to place things on the clip.
/// Controls are meant to float above this view, so the frame can be dragged out from under them.
struct VideoFrameViewer<Overlay: View>: View {
    let scrubber: VideoScrubber
    /// Called with the tapped point on the clip, in pixels of the frame as it is shown. The point is
    /// outside the frame's bounds when the tap lands beside the picture.
    var onTap: ((CGPoint) -> Void)? = nil
    @ViewBuilder var overlay: (VideoViewMapping) -> Overlay

    @State private var zoom: CGFloat = 1
    @State private var zoomAtGestureStart: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var offsetAtGestureStart: CGSize = .zero

    private let maximumZoom: CGFloat = 8
    /// How far, as a fraction of the screen, the frame may be dragged past its edge to clear the controls.
    private let panAllowance: CGFloat = 0.3

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                let mapping = VideoViewMapping(videoSize: scrubber.frames?.displaySize ?? CGSize(width: 16, height: 9), containerSize: geometry.size, zoom: zoom, offset: offset)

                ZStack {
                    PlayerLayerView(player: scrubber.player)
                        .frame(width: mapping.filledSize.width, height: mapping.filledSize.height)
                        .clipShape(.rect(cornerRadius: 24))
                        .scaleEffect(zoom)
                        .offset(offset)
                        // Laid out at the screen's size even though the picture overhangs it, so the overlay
                        // beside it keeps the screen's coordinates.
                        .frame(width: geometry.size.width, height: geometry.size.height)

                    if scrubber.frames != nil {
                        overlay(mapping)
                    } else if scrubber.didFailToLoad {
                        Text("This video couldn't be read.")
                            .customFont(.subheadline, weight: .medium)
                            .foregroundStyle(.white)
                    } else {
                        ProgressView()
                            .tint(.white)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .contentShape(.rect)
                .gesture(magnifyGesture(mapping: mapping).simultaneously(with: panGesture(mapping: mapping)))
                .onTapGesture { location in
                    onTap?(mapping.videoPoint(for: location))
                }
            }
            .coordinateSpace(VideoViewMapping.coordinateSpace)
            .background(.black)
            .ignoresSafeArea()

            if zoom != 1 || offset != .zero {
                Button {
                    withAnimation(.smooth) { resetZoom() }
                } label: {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                        .customFont(.subheadline, weight: .medium)
                        .padding(4)
                }
                .buttonStyle(.glass)
                .environment(\.colorScheme, .dark)
                .accessibilityLabel("Reset Zoom")
                .alignView(to: .trailing)
                .padding()
                .transition(.blurReplace)
            }
        }
    }

    private func magnifyGesture(mapping: VideoViewMapping) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                zoom = min(max(zoomAtGestureStart * value.magnification, mapping.fitZoom), maximumZoom)
                offset = clampedOffset(offset, mapping: mapping)
            }
            .onEnded { _ in
                zoomAtGestureStart = zoom
                offsetAtGestureStart = offset
            }
    }

    private func panGesture(mapping: VideoViewMapping) -> some Gesture {
        DragGesture()
            .onChanged { value in
                offset = clampedOffset(CGSize(width: offsetAtGestureStart.width + value.translation.width, height: offsetAtGestureStart.height + value.translation.height), mapping: mapping)
            }
            .onEnded { _ in
                offsetAtGestureStart = offset
            }
    }

    /// Keeps most of the frame on screen, so it can't be dragged out of sight.
    private func clampedOffset(_ offset: CGSize, mapping: VideoViewMapping) -> CGSize {
        let size = mapping.containerSize
        // How far the zoomed frame overhangs the screen on each side, plus the allowance.
        let maxX = max(mapping.filledSize.width * zoom - size.width, 0) / 2 + panAllowance * size.width
        let maxY = max(mapping.filledSize.height * zoom - size.height, 0) / 2 + panAllowance * size.height
        return CGSize(width: min(max(offset.width, -maxX), maxX), height: min(max(offset.height, -maxY), maxY))
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
