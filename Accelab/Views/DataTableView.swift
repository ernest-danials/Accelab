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
        switch data {
        case .distance:
            self.headings = ["Time (s)", "Distance (m)"]
        case .position:
            self.headings = ["Time (s)", "x (m)", "y (m)"]
        }
        self.rows = CSVExporter.rows(for: data)
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
