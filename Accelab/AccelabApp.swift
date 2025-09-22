//
//  AccelabApp.swift
//  Accelab
//
//  Created by Myung Joon Kang on 2025-09-20.
//

import SwiftUI

@main
struct AccelabApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(AngleManager())
                .environment(MeasuringManager())
        }
    }
}
