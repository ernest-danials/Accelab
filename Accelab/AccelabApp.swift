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
    @State private var rotationMeasuringManager: RotationMeasuringManager = .init()
    @State private var cameraCaptureManager: CameraCaptureManager = .init()
    @State private var methodManager: MethodManager = .init()
    
    var body: some Scene {
        WindowGroup {
            Group {
                switch methodManager.screen {
                case .home:
                    SelectExperimentView()
                case .methods:
                    SelectMethodView()
                case .method(.camera):
                    CameraMethodView(experiment: methodManager.experiment.cameraExperiment)
                case .method(.sensor):
                    // Only opened for an experiment the sensors can do.
                    if let experiment = methodManager.experiment.sensorExperiment {
                        SensorMethodView(experiment: experiment)
                    } else {
                        SelectMethodView()
                    }
                }
            }
            .onOpenURL { url in
                methodManager.open(url)
            }
        }
        .environment(angleManager)
        .environment(motionMeasuringManager)
        .environment(rotationMeasuringManager)
        .environment(cameraCaptureManager)
        .environment(methodManager)
        .modelContainer(for: SavedRun.self)
    }
}
