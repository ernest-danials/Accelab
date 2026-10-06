//
//  DataTableView.swift
//  Accelab
//

import SwiftUI

/// A preview of the run's data as it is written to the CSV file: the same columns and the same digits,
/// under headings written for reading.
struct DataTableView: View {
    let splits: [DistanceSplit]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(splits) { split in
                        row(time: CSVExporter.timeText(for: split), distance: CSVExporter.distanceText(for: split))
                            .monospacedDigit()
                    }
                } header: {
                    row(time: "Time (s)", distance: "Distance (m)")
                        .customFont(.subheadline, weight: .bold)
                        .foregroundStyle(.primary)
                }
            }
            .listStyle(.plain)
            .overlay {
                if splits.isEmpty {
                    ContentUnavailableView("No Data", systemImage: "tablecells")
                }
            }
            .navigationTitle("^[\(splits.count) Row](inflect: true)")
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

    private func row(time: String, distance: String) -> some View {
        HStack {
            Text(time)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(distance)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    DataTableView(splits: (0..<40).map { DistanceSplit(timeElapsed: Double($0) / 60, displacement: 0.3 * pow(Double($0) / 60, 2)) })
}
