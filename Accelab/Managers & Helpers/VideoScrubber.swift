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
    /// The frames being kept for analysis. Nothing outside it can be shown, marked or tracked.
    private(set) var trimRange: ClosedRange<Int> = 0...0

    /// A kept range shorter than this isn't worth analysing.
    static let minimumTrimFrameCount = 5

    init(url: URL) {
        self.url = url
        self.player = AVPlayer(url: url)
        self.player.isMuted = true
    }

    var frameCount: Int { frames?.count ?? 0 }

    /// Seconds since the start of the kept range.
    var currentTime: TimeInterval { seconds(at: currentFrameIndex) - seconds(at: trimRange.lowerBound) }

    /// Seconds since the first frame of the whole clip.
    func seconds(at frameIndex: Int) -> TimeInterval {
        guard let frames, frames.times.indices.contains(frameIndex) else { return 0 }
        return frames.seconds(at: frameIndex)
    }

    func load() async {
        do {
            let frames = try await VideoFrameIndex.load(from: url)
            self.frames = frames
            self.trimRange = 0...(frames.count - 1)
            // Draws the first frame; a player that has never been asked to seek shows nothing.
            seek(toFrame: 0)
        } catch {
            self.didFailToLoad = true
        }
    }

    func seek(toFrame index: Int) {
        guard let frames else { return }

        self.currentFrameIndex = min(max(index, trimRange.lowerBound), trimRange.upperBound)
        // Zero tolerance, so the frame shown is exactly this one rather than the nearest keyframe.
        player.seek(to: frames.times[currentFrameIndex], toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func step(byFrames count: Int) {
        seek(toFrame: currentFrameIndex + count)
    }

    /// Moves by roughly `seconds`, always by at least one frame.
    func step(bySeconds seconds: TimeInterval) {
        guard let frames else { return }

        let target = frames.index(nearest: self.seconds(at: currentFrameIndex) + seconds)
        seek(toFrame: target == currentFrameIndex ? currentFrameIndex + (seconds < 0 ? -1 : 1) : target)
    }

    /// Moves the start of the kept range and shows that frame.
    func setTrimStart(_ index: Int) {
        guard frames != nil else { return }

        let start = min(max(index, 0), max(trimRange.upperBound - Self.minimumTrimFrameCount + 1, 0))
        self.trimRange = start...trimRange.upperBound
        seek(toFrame: start)
    }

    /// Moves the end of the kept range and shows that frame.
    func setTrimEnd(_ index: Int) {
        guard let frames else { return }

        let end = max(min(index, frames.count - 1), min(trimRange.lowerBound + Self.minimumTrimFrameCount - 1, frames.count - 1))
        self.trimRange = trimRange.lowerBound...end
        seek(toFrame: end)
    }
}
