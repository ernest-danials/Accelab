//
//  MethodManager.swift
//  Accelab
//
//  Created by Myung Joon Kang on 2026-10-04.
//

import Observation
import SwiftUI

@Observable
@MainActor
final class MethodManager {
    private(set) var currentMethod: Method? = nil
    
    func changeMethod(to newMethod: Method?) {
        withAnimation {
            self.currentMethod = newMethod
        }
    }
    
    /// Opens the method a deep link names (`accelab://camera`, `accelab://sensor`). Ignored while a method is
    /// already open, so a link can't pull a run out from under its screen.
    func open(_ url: URL) {
        guard url.scheme?.lowercased() == "accelab", currentMethod == nil, let host = url.host()?.lowercased(), let method = Method.allCases.first(where: { $0.rawValue.lowercased() == host }) else { return }
        changeMethod(to: method)
    }
}
