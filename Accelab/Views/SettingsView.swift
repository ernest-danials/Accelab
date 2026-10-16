//
//  SettingsView.swift
//  Accelab
//
//  Created by Myung Joon Kang on 2025-09-22.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query private var runs: [SavedRun]
    
    @State private var isShowingConfirmationDialogToDeleteRuns: Bool = false
    
    @AppStorage(AppStorageKey.marginOfErrorForAngle.rawValue) private var marginOfErrorForAngle: Double = 0.1
    
    var body: some View {
        NavigationStack {
            Form {
                Section("About") {
                    Text("Accelab collects the data for three physics labs. Choose the experiment first: a cart on an air track, a projectile, or circular motion. Then choose how to measure it. The Camera method films the motion and tracks it from the video; the Sensor method puts your iPhone on the thing that moves and reads its built-in sensors. For the air track both give distance against time. A projectile can only be filmed, for its x and y against time. For circular motion the camera gives a marker's position and angle about the centre against time, and the sensors give a turntable's angular velocity and its centripetal and tangential acceleration. Export the data as CSV or for Desmos, and find your finished runs in Past Runs.")
                }
                
                Section {
                    Picker("Margin of Error for Angle", systemImage: "plusminus", selection: $marginOfErrorForAngle) {
                        ForEach(AngleMarginOfError.allCases) { margin in
                            Text("\(margin.rawValue, specifier: "%.2f")°")
                                .tag(margin.rawValue)
                        }
                    }
                } footer: {
                    Text("When you set the track's angle, in either method, the measured angle must be within this margin of the target angle. Levelling your iPhone for a projectile uses the same margin.")
                }
                
                Section {
                    LabeledContent("Saved Runs", value: "\(runs.count)")
                    
                    Button(role: .destructive) {
                        self.isShowingConfirmationDialogToDeleteRuns = true
                    } label: {
                        // Coloured here: in a form the icon takes the accent colour, and neither part dims when disabled.
                        Label {
                            Text("Delete All Past Runs")
                        } icon: {
                            Image(systemName: "trash")
                                .foregroundStyle(runs.isEmpty ? Color.secondary : Color.red)
                        }
                        .foregroundStyle(runs.isEmpty ? Color.secondary : Color.red)
                    }
                    .disabled(runs.isEmpty)
                    .confirmationDialog(runs.count == 1 ? "This will delete your past run. Are you sure?" : "This will delete all \(runs.count) past runs. Are you sure?", isPresented: $isShowingConfirmationDialogToDeleteRuns, titleVisibility: .visible) {
                        Button("Yes, delete", role: .destructive, action: deleteAllRuns)
                    }
                } header: {
                    Text("Past Runs")
                } footer: {
                    Text("Runs you finish are saved automatically. Videos aren't kept.")
                }
                
                Section {
                    Link(destination: URL(string: "https://myungjoon.com/accelab")!) {
                        Label("Project Website", systemImage: "arrow.up.right")
                    }
                    
                    Link(destination: URL(string: "https://myungjoon.com")!) {
                        Label("Developer Website", systemImage: "arrow.up.right")
                    }
                }
                
                Section {
                    Link(destination: URL(string: "https://github.com/ernest-danials/Accelab")!) {
                        Label("GitHub Repository", systemImage: "arrow.up.right")
                    }
                } footer: {
                    Text("Accelab is an open-source project and open for contributions.")
                }
                
                Section {
                    Link(destination: URL(string: "https://myungjoon.com/accelab/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }
                } footer: {
                    Text("Version: \(Bundle.main.versionBuildString) \nCopyright © 2025–2026 Myung-Joon Kang. All rights reserved.")
                }
            }
            .navigationTitle("Settings")
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
    
    private func deleteAllRuns() {
        for run in runs {
            modelContext.delete(run)
        }
        Haptics.success()
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: SavedRun.self, inMemory: true)
}
