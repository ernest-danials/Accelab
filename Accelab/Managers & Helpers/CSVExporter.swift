//
//  CSVExporter.swift
//  Accelab
//

import Foundation

/// Turns a run's samples into a CSV file in the temporary directory for sharing.
enum CSVExporter {
    private static let filePrefix = "accelab-"

    static func makeCSV(from data: RunData) -> String {
        ([columns(for: data).joined(separator: ",")] + rows(for: data).map { $0.joined(separator: ",") }).joined(separator: "\n")
    }

    /// The samples as rows of tab-separated numbers with no header, which is what Desmos turns into a
    /// table when pasted into an empty expression line. Desmos starts a new table every 1000 rows.
    static func makeDesmosText(from data: RunData) -> String {
        rows(for: data).map { $0.joined(separator: "\t") }.joined(separator: "\n")
    }

    /// The names in the file's header row, one for each column.
    static func columns(for data: RunData) -> [String] {
        switch data {
        case .distance:
            return ["time_s", "distance_m"]
        case .position:
            return ["time_s", "x_m", "y_m"]
        case .rotation:
            return ["time_s", "angular_velocity_rad_s", "angular_velocity_squared_rad2_s2", "centripetal_acceleration_m_s2", "tangential_acceleration_m_s2"]
        case .circle:
            return ["time_s", "x_m", "y_m", "angle_rad", "radius_m"]
        }
    }

    /// Every sample exactly as it is exported, so anything showing the data matches the file.
    static func rows(for data: RunData) -> [[String]] {
        switch data {
        case .distance(let splits):
            return splits.map { [timeText(for: $0.timeElapsed), lengthText(for: $0.displacement)] }
        case .position(let splits):
            return splits.map { [timeText(for: $0.timeElapsed), lengthText(for: $0.x), lengthText(for: $0.y)] }
        case .rotation(let splits):
            return splits.map { [timeText(for: $0.timeElapsed), valueText(for: $0.angularVelocity), valueText(for: $0.angularVelocity * $0.angularVelocity), valueText(for: $0.centripetalAcceleration), valueText(for: $0.tangentialAcceleration)] }
        case .circle(let splits):
            return splits.map { [timeText(for: $0.timeElapsed), lengthText(for: $0.x), lengthText(for: $0.y), valueText(for: $0.angle), lengthText(for: $0.radius)] }
        }
    }

    private static func timeText(for seconds: TimeInterval) -> String {
        String(format: "%.4f", seconds)
    }

    private static func lengthText(for meters: Double) -> String {
        let text = String(format: "%.5f", meters)
        // A value that rounds to nothing keeps its minus sign, which reads as a mistake in a table.
        return text == "-0.00000" ? "0.00000" : text
    }

    /// An angular velocity, an acceleration or an angle, which only needs four decimals: a sensor is not as
    /// exact as a ruler in a video, and a ten-thousandth of a radian is well under a pixel on any circle that fits the frame.
    private static func valueText(for value: Double) -> String {
        let text = String(format: "%.4f", value)
        // Same as `lengthText`: a value that rounds to nothing loses its minus sign.
        return text == "-0.0000" ? "0.0000" : text
    }

    /// The date and time used in the names of exported files. Avoids ':' (as in ISO 8601), which Finder
    /// shows as '/' and Windows rejects in file names.
    nonisolated static func makeFileStamp() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: Date())
    }

    /// Writes the samples to a fresh temp file, deleting earlier exports first. Returns `nil` if writing failed.
    static func writeTempFile(for data: RunData) -> URL? {
        removeTempFiles()

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(filePrefix)\(makeFileStamp()).csv")

        do {
            try makeCSV(from: data).write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    /// Writes the samples as a text file Desmos can import, next to the CSV. Returns `nil` if writing failed.
    static func writeDesmosTempFile(for data: RunData) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(filePrefix)desmos-\(makeFileStamp()).txt")

        do {
            try makeDesmosText(from: data).write(to: url, atomically: true, encoding: .utf8)
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
