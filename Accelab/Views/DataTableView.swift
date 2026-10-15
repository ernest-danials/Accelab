//
//  DataTableView.swift
//  Accelab
//

import SwiftUI

/// A preview of the run's data as it is written to the CSV file: the same columns and the same digits,
/// under headings written for reading.
struct DataTableView: View {
    private let headings: [String]
    /// Every row as text, read once from the exporter rather than on each redraw.
    private let rows: [[String]]

    @Environment(\.dismiss) private var dismiss

    init(data: RunData) {
        self.headings = Self.columnHeadings(for: data)
        self.rows = CSVExporter.rows(for: data)
    }

    /// The columns' headings, written for reading. Also what VoiceOver reads for the columns on the screen where a method is chosen.
    static func columnHeadings(for data: RunData) -> [String] {
        switch data {
        case .distance:
            return ["Time (s)", "Distance (m)"]
        case .position:
            return ["Time (s)", "x (m)", "y (m)"]
        case .rotation:
            return ["Time (s)", "ω (rad/s)", "ω² (rad²/s²)", "Centripetal (m/s²)", "Tangential (m/s²)"]
        case .circle:
            return ["Time (s)", "x (m)", "y (m)", "θ (rad)", "Radius (m)"]
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(rows.indices, id: \.self) { index in
                        row(rows[index])
                            .monospacedDigit()
                    }
                } header: {
                    row(headings)
                        .customFont(.subheadline, weight: .bold)
                        .foregroundStyle(.primary)
                }
            }
            .listStyle(.plain)
            .overlay {
                if rows.isEmpty {
                    ContentUnavailableView("No Data", systemImage: "tablecells")
                }
            }
            .navigationTitle("^[\(rows.count) Row](inflect: true)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) {
                        dismiss()
                    }
                }
            }
        }
    }

    /// One line of the table, its cells sharing the width equally.
    private func row(_ cells: [String]) -> some View {
        HStack {
            ForEach(cells.indices, id: \.self) { index in
                Text(cells[index])
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

#Preview("Distance") {
    DataTableView(data: .distance((0..<40).map { DistanceSplit(timeElapsed: Double($0) / 60, displacement: 0.3 * pow(Double($0) / 60, 2)) }))
}

#Preview("Projectile") {
    DataTableView(data: .position((0..<40).map { PositionSplit(timeElapsed: Double($0) / 60, x: 2.5 * Double($0) / 60, y: 3 * Double($0) / 60 - 4.905 * pow(Double($0) / 60, 2)) }))
}

#Preview("Circle") {
    DataTableView(data: .circle((0..<40).map { index in
        let angle = 2 * Double.pi * Double(index) / 30
        return CircleSplit(timeElapsed: Double(index) / 15, x: 0.2 * cos(angle), y: 0.2 * sin(angle), angle: angle, radius: 0.2)
    }))
}

#Preview("Circular Motion") {
    DataTableView(data: .rotation((0..<40).map { index in
        let angularVelocity = index < 20 ? 0.4 * Double(index) : 0.4 * Double(40 - index)
        return RotationSplit(timeElapsed: Double(index) / 4, angularVelocity: angularVelocity, centripetalAcceleration: angularVelocity * angularVelocity * 0.15, tangentialAcceleration: index < 20 ? 0.06 : -0.06)
    }))
}
