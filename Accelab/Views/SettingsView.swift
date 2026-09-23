//
//  SettingsView.swift
//  Accelab
//
//  Created by Myung Joon Kang on 2025-09-22.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage(AppStorageKey.marginOfErrorForAngle.rawValue) private var marginOfErrorForAngle: Double = 0.1
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Margin of Error for Angle", systemImage: "plusminus", selection: $marginOfErrorForAngle) {
                        ForEach(AngleMarginOfError.allCases) { margin in
                            Text("\(margin.rawValue, specifier: "%.2f")°")
                                .tag(margin.rawValue)
                        }
                    }
                } footer: {
                    Text("The angle difference between the measured and target angle must be within this margin of error.")
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
                    Link(destination: URL(string: "https://myungjoon.com/accelab/support")!) {
                        Label("Need help?", systemImage: "lifepreserver.fill")
                    }
                    
                    Link(destination: URL(string: "https://myungjoon.com/accelab/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }
                } footer: {
                    Text("Version: \(Bundle.main.versionBuildString) \nCopyright © 2025 Myung-Joon Kang. All rights reserved.")
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
}

#Preview {
    SettingsView()
}
