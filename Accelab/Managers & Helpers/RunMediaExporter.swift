//
//  RunMediaExporter.swift
//  Accelab
//

import AVFoundation
import UIKit

/// Makes the shareable media of a camera run in the temporary directory: the recorded clip under a
/// readable name, and a photo of the last tracked frame with every tracked point drawn on it.
nonisolated enum RunMediaExporter {
    private static let filePrefix = "accelab-run-"

    /// Gives the clip a name worth sharing without copying it where a hard link will do.
    /// The whole recording is exported, not just the trimmed range. Returns `nil` if that failed.
    static func makeVideoFile(from clipURL: URL) -> URL? {
        let fileManager = FileManager.default
        let url = makeTempURL(pathExtension: clipURL.pathExtension.isEmpty ? "mov" : clipURL.pathExtension)

        do {
            try fileManager.linkItem(at: clipURL, to: url)
            return url
        } catch {
            return (try? fileManager.copyItem(at: clipURL, to: url)) != nil ? url : nil
        }
    }

    /// Draws every point on the frame of the last one and writes it as a JPEG. Returns `nil` if there
    /// are no points or the frame couldn't be read.
    @concurrent
    static func makePhotoFile(from clipURL: URL, frames: VideoFrameIndex, points: [TrackedPoint]) async -> URL? {
        guard let lastPoint = points.max(by: { $0.frameIndex < $1.frameIndex }), frames.times.indices.contains(lastPoint.frameIndex) else { return nil }

        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: clipURL))
        // Rotated as it is shown, which is the orientation the points are stored in.
        generator.appliesPreferredTrackTransform = true
        // Zero tolerance, so the frame is exactly the one the last point was marked on.
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        guard let frame = try? await generator.image(at: frames.times[lastPoint.frameIndex]).image else { return nil }

        // Drawn at the size the points are measured in, whatever size the generator returned.
        let size = frames.displaySize
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        let radius = max(size.width, size.height) / 240
        let data = UIGraphicsImageRenderer(size: size, format: format).jpegData(withCompressionQuality: 0.9) { context in
            UIImage(cgImage: frame).draw(in: CGRect(origin: .zero, size: size))

            context.cgContext.setLineWidth(radius / 4)
            context.cgContext.setStrokeColor(UIColor.white.cgColor)

            for point in points {
                // The same colours as the trail on the tracking screen.
                let isUncertain = !point.isManual && point.confidence < VideoTracker.uncertainConfidence
                context.cgContext.setFillColor((isUncertain ? UIColor.systemOrange : UIColor.systemYellow).cgColor)
                context.cgContext.addEllipse(in: CGRect(x: point.position.x - radius, y: point.position.y - radius, width: radius * 2, height: radius * 2))
                context.cgContext.drawPath(using: .fillStroke)
            }
        }

        let url = makeTempURL(pathExtension: "jpg")
        return (try? data.write(to: url, options: .atomic)) != nil ? url : nil
    }

    static func removeTempFiles() {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: fileManager.temporaryDirectory, includingPropertiesForKeys: nil) else { return }

        for file in files where file.lastPathComponent.hasPrefix(filePrefix) {
            try? fileManager.removeItem(at: file)
        }
    }

    private static func makeTempURL(pathExtension: String) -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("\(filePrefix)\(CSVExporter.makeFileStamp())").appendingPathExtension(pathExtension)
    }
}
