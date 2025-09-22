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
                        Text("Project Website")
                    }
                    
                    Link(destination: URL(string: "https://myungjoon.com")!) {
                        Text("Developer Website")
                    }
                }
                
                Section {
                    Link(destination: URL(string: "https://myungjoon.com/accelab/privacy")!) {
                        Text("GitHub Repository")
                    }
                } footer: {
                    Text("Accelab is an open-source project and open for contributions.")
                }
                
                Section {
                    Link(destination: URL(string: "https://myungjoon.com/accelab/privacy")!) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                            
                            Text("Privacy Policy")
                        }
                    }
                } footer: {
                    Text("Version: \(Bundle.main.versionBuildString) \nCopyright © 2025 Myung-Joon Kang. All rights reserved.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
