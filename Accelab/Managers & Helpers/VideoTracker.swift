//
//  VideoTracker.swift
//  Accelab
//

import AVFoundation
import CoreGraphics
import ImageIO
import Vision

/// Follows an object through a clip with Vision's object tracker, starting from a box drawn around it.
nonisolated enum VideoTracker {
    /// Below this, Vision has most likely lost the object, so tracking stops and says so.
    static let lostConfidence: Double = 0.3
    /// Below this, a point is worth a second look.
    static let uncertainConfidence: Double = 0.5

    enum TrackingError: Error {
        case noVideoTrack, unreadable
        /// Vision stopped being able to follow the object before the last frame.
        case lost
    }

    /// Yields the centre of the tracked box for `startFrame` and every frame after it up to `endFrame`. The
    /// stream ends quietly at `endFrame` or when the consuming task is cancelled, and throws
    /// `TrackingError.lost` if the object is lost first, so that stopping early is never mistaken for
    /// having finished.
    ///
    /// - Parameter box: The object on `startFrame`, in pixels of the frame as it is shown.
    static func track(url: URL, frames: VideoFrameIndex, startFrame: Int, endFrame: Int, box: CGRect) -> AsyncThrowingStream<TrackedPoint, Error> {
        AsyncThrowingStream { continuation in
            let task = Task.detached(priority: .userInitiated) {
                do {
                    try await run(url: url, frames: frames, startFrame: startFrame, endFrame: endFrame, box: box) { continuation.yield($0) }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private static func run(url: URL, frames: VideoFrameIndex, startFrame: Int, endFrame: Int, box: CGRect, yield: (TrackedPoint) -> Void) async throws {
        let asset = AVURLAsset(url: url)
        guard let track = try await asset.loadTracks(withMediaType: .video).first else { throw TrackingError.noVideoTrack }

        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange])
        output.alwaysCopiesSampleData = false
        reader.add(output)
        reader.timeRange = CMTimeRange(start: frames.times[startFrame], duration: .positiveInfinity)
        guard reader.startReading() else { throw reader.error ?? TrackingError.unreadable }
        defer { reader.cancelReading() }

        let orientation = imageOrientation(for: frames.preferredTransform)
        let displaySize = frames.displaySize
        let handler = VNSequenceRequestHandler()

        let request = VNTrackObjectRequest(detectedObjectObservation: VNDetectedObjectObservation(boundingBox: visionRect(for: box, displaySize: displaySize)))
        request.trackingLevel = .accurate

        while let sampleBuffer = output.copyNextSampleBuffer() {
            try Task.checkCancellation()
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { continue }

            // The reader may hand back frames from before the requested start.
            let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            guard time >= frames.times[startFrame] else { continue }

            // Looked up from the timestamp rather than counted, in case the decoder skips or repeats a frame.
            let frameIndex = frames.index(nearest: (time - frames.times[0]).seconds)
            guard frameIndex <= endFrame else { break }

            if frameIndex == startFrame {
                // The drawn box is the answer for the first frame; the tracker only needs to see it.
                try handler.perform([request], on: pixelBuffer, orientation: orientation)
                yield(TrackedPoint(frameIndex: frameIndex, position: CGPoint(x: box.midX, y: box.midY), isManual: false, confidence: 1))
            } else {
                try handler.perform([request], on: pixelBuffer, orientation: orientation)
                guard let observation = request.results?.first as? VNDetectedObjectObservation else { throw TrackingError.lost }

                let confidence = Double(observation.confidence)
                guard confidence >= lostConfidence else { throw TrackingError.lost }

                yield(TrackedPoint(frameIndex: frameIndex, position: displayPoint(forCenterOf: observation.boundingBox, displaySize: displaySize), isManual: false, confidence: confidence))
                request.inputObservation = observation
            }
        }

        // Running out of frames is finishing; the reader giving up partway is not.
        if reader.status == .failed { throw reader.error ?? TrackingError.unreadable }
    }

    // MARK: - Vision coordinates
    // Vision works on the upright image with a normalised, bottom-left origin. These are the only places
    // that convert to and from the top-left pixel coordinates used everywhere else.

    private static func visionRect(for box: CGRect, displaySize: CGSize) -> CGRect {
        CGRect(x: box.minX / displaySize.width, y: 1 - box.maxY / displaySize.height, width: box.width / displaySize.width, height: box.height / displaySize.height)
    }

    private static func displayPoint(forCenterOf boundingBox: CGRect, displaySize: CGSize) -> CGPoint {
        CGPoint(x: boundingBox.midX * displaySize.width, y: (1 - boundingBox.midY) * displaySize.height)
    }

    /// How the stored frames must be turned to appear upright.
    private static func imageOrientation(for transform: CGAffineTransform) -> CGImagePropertyOrientation {
        switch (transform.a, transform.b, transform.c, transform.d) {
        case (0, 1, -1, 0): return .right
        case (0, -1, 1, 0): return .left
        case (-1, 0, 0, -1): return .down
        default: return .up
        }
    }
}
