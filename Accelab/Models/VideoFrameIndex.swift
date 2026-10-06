//
//  VideoFrameIndex.swift
//  Accelab
//

import AVFoundation
import CoreGraphics

/// Every frame of a clip in presentation order, so a frame's time is read from the file rather than
/// assumed from a frame rate (iPhone video isn't guaranteed to be evenly spaced).
nonisolated struct VideoFrameIndex: Sendable {
    let times: [CMTime]
    /// The frame size as it is shown, after the track's rotation has been applied.
    let displaySize: CGSize
    let preferredTransform: CGAffineTransform

    var count: Int { times.count }

    /// Seconds since the first frame.
    func seconds(at index: Int) -> TimeInterval {
        (times[index] - times[0]).seconds
    }

    /// The frame shown closest to `seconds` after the first frame.
    func index(nearest seconds: TimeInterval) -> Int {
        var low = 0
        var high = times.count - 1

        while low < high {
            let middle = (low + high) / 2
            if self.seconds(at: middle) < seconds {
                low = middle + 1
            } else {
                high = middle
            }
        }

        if low > 0, abs(self.seconds(at: low - 1) - seconds) <= abs(self.seconds(at: low) - seconds) {
            return low - 1
        }
        return low
    }

    enum LoadError: Error {
        case noVideoTrack, unreadable
    }

    /// Reads the timestamps without decoding any frames.
    @concurrent
    static func load(from url: URL) async throws -> VideoFrameIndex {
        let asset = AVURLAsset(url: url)
        guard let track = try await asset.loadTracks(withMediaType: .video).first else { throw LoadError.noVideoTrack }
        let (naturalSize, preferredTransform) = try await track.load(.naturalSize, .preferredTransform)

        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: nil)
        output.alwaysCopiesSampleData = false
        reader.add(output)
        guard reader.startReading() else { throw reader.error ?? LoadError.unreadable }

        var times: [CMTime] = []
        while let sampleBuffer = output.copyNextSampleBuffer() {
            guard CMSampleBufferGetNumSamples(sampleBuffer) > 0 else { continue }

            let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            if time.isValid { times.append(time) }
        }

        guard reader.status == .completed, !times.isEmpty else { throw reader.error ?? LoadError.unreadable }

        // Samples arrive in decode order, which differs from presentation order when frames are reordered.
        times.sort()

        let displayRect = CGRect(origin: .zero, size: naturalSize).applying(preferredTransform)
        return VideoFrameIndex(times: times, displaySize: CGSize(width: abs(displayRect.width), height: abs(displayRect.height)), preferredTransform: preferredTransform)
    }
}
