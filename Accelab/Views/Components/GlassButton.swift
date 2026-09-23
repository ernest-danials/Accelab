//
//  GlassButton.swift
//  Accelab
//
//  Created by Myung Joon Kang on 2025-09-21.
//

import SwiftUI

struct GlassButton: View {
    let text: String
    let style: GlassButtonStyle
    let textFont: Font.TextStyle
    let isDisabled: Bool
    let action: () -> Void

    init(text: String, style: GlassButtonStyle = .prominent, textFont: Font.TextStyle = .title3, isDisabled: Bool = false, perform action: @escaping () -> Void) {
        self.text = text
        self.style = style
        self.textFont = textFont
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        switch self.style {
        case .prominent:
            button.buttonStyle(.glassProminent)
        case .secondary:
            button.buttonStyle(.glass)
        }
    }

    private var button: some View {
        Button(action: action) {
            Text(text)
                .customFont(textFont, weight: .medium)
                .padding(.vertical, 5)
                .padding(.horizontal, 20)
        }
        .disabled(isDisabled)
    }

    enum GlassButtonStyle {
        case prominent, secondary
    }
}
