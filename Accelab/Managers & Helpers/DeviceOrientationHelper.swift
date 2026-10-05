//
//  DeviceOrientationHelper.swift
//  Accelab
//
//  Created by Myung Joon Kang on 2025-09-20.
//

import SwiftUI
import UIKit
import Combine

struct DeviceRotationHelperViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void
    
    @State private var interfaceGeometryPublisher: AnyPublisher<Void, Never> = Empty().eraseToAnyPublisher()
    
    private var windowScene: UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first
    }
    
    /// Resolves the landscape side from the interface rather than `UIDevice.orientation`, which stops
    /// updating under orientation lock and reports portrait on a steep track.
    private func resolveCurrentOrientation() -> UIDeviceOrientation {
        // Interface and device landscape orientations are mirrored.
        switch windowScene?.effectiveGeometry.interfaceOrientation {
        case .landscapeLeft: return .landscapeRight
        case .landscapeRight: return .landscapeLeft
        default: return .unknown
        }
    }
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                UIDevice.current.beginGeneratingDeviceOrientationNotifications()
                if let windowScene {
                    self.interfaceGeometryPublisher = windowScene.publisher(for: \.effectiveGeometry, options: [.new]).map { _ in () }.eraseToAnyPublisher()
                }
                DispatchQueue.main.async {
                    action(resolveCurrentOrientation())
                }
            }
            .onDisappear {
                UIDevice.current.endGeneratingDeviceOrientationNotifications()
            }
            .onReceive(interfaceGeometryPublisher) { _ in
                action(resolveCurrentOrientation())
            }
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(resolveCurrentOrientation())
                // The interface may not have rotated yet, so resolve again once it has settled.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    action(resolveCurrentOrientation())
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                action(resolveCurrentOrientation())
            }
    }
}

extension View {
    /// Reports which landscape side the interface is on, expressed as the matching device orientation.
    func onDeviceRotation(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationHelperViewModifier(action: action))
    }
}
