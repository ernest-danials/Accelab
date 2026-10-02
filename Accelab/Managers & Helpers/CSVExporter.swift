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
            rows.append(String(format: "%.4f,%.5f", split.timeElapsed, split.displacement))
        }
        return rows.joined(separator: "\n")
    }

    /// Writes the splits to a fresh temp file, deleting earlier exports first. Returns `nil` if writing failed.
    static func writeTempFile(for splits: [DistanceSplit]) -> URL? {
        removeTempFiles()

        // Avoid ':' (as in ISO 8601), which Finder shows as '/' and Windows rejects in file names.
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let stamp = formatter.string(from: Date())

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(filePrefix)\(stamp).csv")

        do {
            try makeCSV(from: splits).write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    static func removeTempFiles() {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: fileManager.temporaryDirectory, includingPropertiesForKeys: nil) else { return }

        for file in files where file.lastPathComponent.hasPrefix(filePrefix) && file.pathExtension == "csv" {
            try? fileManager.removeItem(at: file)
        }
    }
}
