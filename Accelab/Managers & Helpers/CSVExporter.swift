//
//  CSVExporter.swift
//  Accelab
//

import Foundation

/// Turns a run's splits into a CSV file in the temporary directory for sharing.
enum CSVExporter {
    private static let filePrefix = "accelab-"

    static func makeCSV(from splits: [DistanceSplit]) -> String {
        var rows = ["time_s,distance_m"]
        rows.reserveCapacity(splits.count + 1)
        for split in splits {
            rows.append("\(timeText(for: split)),\(distanceText(for: split))")
        }
        return rows.joined(separator: "\n")
    }

    /// The splits as rows of tab-separated numbers with no header, which is what Desmos turns into a
    /// table when pasted into an empty expression line. Desmos starts a new table every 1000 rows.
    static func makeDesmosText(from splits: [DistanceSplit]) -> String {
        splits.map { "\(timeText(for: $0))\t\(distanceText(for: $0))" }.joined(separator: "\n")
    }

    /// A split's time exactly as it is exported, so anything showing the data matches the file.
    static func timeText(for split: DistanceSplit) -> String {
        String(format: "%.4f", split.timeElapsed)
    }

    /// A split's distance exactly as it is exported.
    static func distanceText(for split: DistanceSplit) -> String {
        String(format: "%.5f", split.displacement)
    }

    /// The date and time used in the names of exported files. Avoids ':' (as in ISO 8601), which Finder
    /// shows as '/' and Windows rejects in file names.
    nonisolated static func makeFileStamp() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: Date())
    }

    /// Writes the splits to a fresh temp file, deleting earlier exports first. Returns `nil` if writing failed.
    static func writeTempFile(for splits: [DistanceSplit]) -> URL? {
        removeTempFiles()

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(filePrefix)\(makeFileStamp()).csv")

        do {
            try makeCSV(from: splits).write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    /// Writes the splits as a text file Desmos can import, next to the CSV. Returns `nil` if writing failed.
    static func writeDesmosTempFile(for splits: [DistanceSplit]) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(filePrefix)desmos-\(makeFileStamp()).txt")

        do {
            try makeDesmosText(from: splits).write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    static func removeTempFiles() {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: fileManager.temporaryDirectory, includingPropertiesForKeys: nil) else { return }

        for file in files where file.lastPathComponent.hasPrefix(filePrefix) && ["csv", "txt"].contains(file.pathExtension) {
            try? fileManager.removeItem(at: file)
        }
    }
}
