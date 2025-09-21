//
//  DeviceOrientationHelper.swift
//  Accelab
//
//  Created by Myung Joon Kang on 2025-09-20.
//

import SwiftUI
import UIKit

struct DeviceRotationHelperViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void
    
    private func resolveCurrentOrientation() -> UIDeviceOrientation {
        let device = UIDevice.current
        if device.orientation != .unknown { return device.orientation }
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            switch scene.interfaceOrientation {
            case .portrait: return .portrait
            case .portraitUpsideDown: return .portraitUpsideDown
            case .landscapeLeft: return .landscapeLeft
            case .landscapeRight: return .landscapeRight
            default: return .unknown
            }
        }
        return .unknown
    }
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                UIDevice.current.beginGeneratingDeviceOrientationNotifications()
                DispatchQueue.main.async {
                    action(resolveCurrentOrientation())
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(resolveCurrentOrientation())
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                action(resolveCurrentOrientation())
            }
    }
}

extension View {
    func onDeviceRotation(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationHelperViewModifier(action: action))
    }
}
