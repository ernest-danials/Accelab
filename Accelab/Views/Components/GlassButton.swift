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
            if #available(iOS 26.0, *) {
                Button {
                    action()
                } label: {
                    Text(text)
                        .customFont(textFont, weight: .medium)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 20)
                }
                .buttonStyle(.glassProminent)
                .disabled(isDisabled)
            } else {
                Button {
                    action()
                } label: {
                    Text(text)
                        .customFont(textFont, weight: .medium)
                        .foregroundStyle(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 25)
                        .background(.accent.gradient)
                        .clipShape(.capsule)
                        .opacity(isDisabled ? 0.7 : 1.0)
                }
                .scaleButtonStyle(scaleAmount: isDisabled ? 1.0 : 0.98)
                .disabled(isDisabled)
            }
        case .secondary:
            if #available(iOS 26.0, *) {
                Button {
                    action()
                } label: {
                    Text(text)
                        .customFont(textFont, weight: .medium)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 20)
                }
                .buttonStyle(.glass)
                .disabled(isDisabled)
            } else {
                Button {
                    action()
                } label: {
                    Text(text)
                        .customFont(textFont, weight: .medium)
                        .foregroundStyle(.accent)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 25)
                        .background {
                            Capsule()
                                .fill(.white)
                                .shadow(color: .black.opacity(0.2), radius: 5)
                        }
                        .opacity(isDisabled ? 0.7 : 1.0)
                }
                .scaleButtonStyle(scaleAmount: isDisabled ? 1.0 : 0.98)
                .disabled(isDisabled)
            }
        }
    }
    
    enum GlassButtonStyle {
        case prominent, secondary
    }
}
