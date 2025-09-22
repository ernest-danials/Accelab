//
//  AngleMarginOfError.swift
//  Accelab
//
//  Created by Myung Joon Kang on 2025-09-22.
//

import Foundation

enum AngleMarginOfError: Double, Identifiable, CaseIterable {
    case pointZeroFive = 0.05
    case pointOne = 0.1
    case pointTwoFive = 0.25
    case pointFive = 0.5
    case one = 1.0
    
    var id: Self { self }
}
