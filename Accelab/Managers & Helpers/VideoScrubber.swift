//
//  VideoScrubber.swift
//  Accelab
//

import AVFoundation
import Observation

/// Shows one frame of a clip at a time: the player never plays, it only seeks to exact frames.
@Observable
final class VideoScrubber {
    let url: URL
    let player: AVPlayer

    /// `nil` until `load()` has read the clip.
    private(set) var frames: VideoFrameIndex? = nil
    private(set) var didFailToLoad: Bool = false
    private(set) var currentFrameIndex: Int = 0

    init(url: URL) {
        self.url = url
        self.player = AVPlayer(url: url)
        self.player.isMuted = true
    }

    var frameCount: Int { frames?.count ?? 0 }

    /// Seconds since the first frame.
    var currentTime: TimeInterval { frames?.seconds(at: currentFrameIndex) ?? 0 }

    func load() async {
        do {
            self.frames = try await VideoFrameIndex.load(from: url)
            // Draws the first frame; a player that has never been asked to seek shows nothing.
            seek(toFrame: 0)
        } catch {
            self.didFailToLoad = true
        }
    }

    func seek(toFrame index: Int) {
        guard let frames else { return }

        self.currentFrameIndex = min(max(index, 0), frames.count - 1)
        // Zero tolerance, so the frame shown is exactly this one rather than the nearest keyframe.
        player.seek(to: frames.times[currentFrameIndex], toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func step(byFrames count: Int) {
        seek(toFrame: currentFrameIndex + count)
    }

    /// Moves by roughly `seconds`, always by at least one frame.
    func step(bySeconds seconds: TimeInterval) {
        guard let frames else { return }

        let target = frames.index(nearest: currentTime + seconds)
        seek(toFrame: target == currentFrameIndex ? currentFrameIndex + (seconds < 0 ? -1 : 1) : target)
    }
}
