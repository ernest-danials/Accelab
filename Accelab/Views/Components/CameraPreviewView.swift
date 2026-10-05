//
//  CameraPreviewView.swift
//  Accelab
//

import AVFoundation
import SwiftUI

/// The live picture from the camera, kept upright as the phone is turned.
struct CameraPreviewView: UIViewRepresentable {
    let captureManager: CameraCaptureManager

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.videoGravity = .resizeAspect
        view.previewLayer.session = captureManager.session
        view.follow(captureManager.attach(previewLayer: view.previewLayer))
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

        private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
        private var rotationObservation: NSKeyValueObservation?

        func follow(_ rotationCoordinator: AVCaptureDevice.RotationCoordinator?) {
            self.rotationCoordinator = rotationCoordinator
            self.rotationObservation = rotationCoordinator?.observe(\.videoRotationAngleForHorizonLevelPreview, options: [.initial, .new]) { [weak self] coordinator, _ in
                let angle = coordinator.videoRotationAngleForHorizonLevelPreview
                Task { @MainActor [weak self] in
                    self?.setPreviewRotationAngle(angle)
                }
            }
        }

        private func setPreviewRotationAngle(_ angle: CGFloat) {
            guard let connection = previewLayer.connection, connection.isVideoRotationAngleSupported(angle) else { return }
            connection.videoRotationAngle = angle
        }
    }
}
