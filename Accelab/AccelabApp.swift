//
//  AccelabApp.swift
//  Accelab
//
//  Created by Myung Joon Kang on 2025-09-20.
//

import SwiftUI
import SwiftData

@main
struct AccelabApp: App {
    @State private var angleManager: AngleManager = .init()
    @State private var motionMeasuringManager: MotionMeasuringManager = .init()
    @State private var cameraCaptureManager: CameraCaptureManager = .init()
    @State private var methodManager: MethodManager = .init()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if let currentMethod = methodManager.currentMethod {
                    switch currentMethod {
                    case .camera, .projectile:
                        CameraMethodView(method: currentMethod)
                    case .sensor:
                        SensorMethodView()
                    }
                } else {
                    SelectMethodView()
                }
            }
            .onOpenURL { url in
                methodManager.open(url)
            }
        }
        .environment(angleManager)
        .environment(motionMeasuringManager)
        .environment(cameraCaptureManager)
        .environment(methodManager)
        .modelContainer(for: SavedRun.self)
    }
}
