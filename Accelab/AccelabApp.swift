//
//  AccelabApp.swift
//  Accelab
//
//  Created by Myung Joon Kang on 2025-09-20.
//

import SwiftUI

@main
struct AccelabApp: App {
    @State private var angleManager: AngleManager = .init()
    @State private var motionMeasuringManager: MotionMeasuringManager = .init()
    @State private var methodManager: MethodManager = .init()
    
    var body: some Scene {
        WindowGroup {
            if let currentMethod = methodManager.currentMethod {
                switch currentMethod {
                case .camera:
                    CameraMethodView()
                case .sensor:
                    SensorMethodView()
                }
            } else {
                SelectMethodView()
            }
        }
        .environment(angleManager)
        .environment(motionMeasuringManager)
        .environment(methodManager)
    }
}
