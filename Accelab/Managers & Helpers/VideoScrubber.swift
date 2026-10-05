//
//  VideoScrubber.swift
//  Accelab
//

import AVFoundation
import Observation

/// Shows one frame of a clip at a time: the player never plays, it only seeks.
@Observable
final class VideoScrubber {
    let player: AVPlayer

    private(set) var duration: TimeInterval = 0
    private(set) var frameDuration: TimeInterval = 1.0 / 30.0
    private(set) var currentTime: TimeInterval = 0

    init(url: URL) {
        self.player = AVPlayer(url: url)
        self.player.isMuted = true
    }

    /// Reads the clip's length and frame rate. Until this finishes the scrubber has nowhere to seek.
    func load() async {
        guard let asset = player.currentItem?.asset else { return }

        if let duration = try? await asset.load(.duration), duration.seconds.isFinite {
            self.duration = duration.seconds
        }

        if let track = try? await asset.loadTracks(withMediaType: .video).first, let frameRate = try? await track.load(.nominalFrameRate), frameRate > 0 {
            self.frameDuration = 1.0 / Double(frameRate)
        }
    }

    func seek(to time: TimeInterval) {
        self.currentTime = min(max(time, 0), duration)
        // Zero tolerance, so the frame shown is the one at this time rather than the nearest keyframe.
        player.seek(to: CMTime(seconds: currentTime, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func step(byFrames count: Int) {
        seek(to: currentTime + Double(count) * frameDuration)
    }
}
