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
}
