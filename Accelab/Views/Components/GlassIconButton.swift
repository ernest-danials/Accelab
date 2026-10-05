//
//  GlassIconButton.swift
//  Accelab
//

import SwiftUI

/// A glass button that shows an icon, with a short title beside it only when the icon alone wouldn't be
/// understood. Every one is the same height, so a row of them lines up with the other glass controls.
struct GlassIconButton: View {
    let systemImage: String
    let title: String?
    /// Read by VoiceOver in place of the icon.
    let label: String
    let style: GlassButton.GlassButtonStyle
    let isDisabled: Bool
    let action: () -> Void

    /// The height shared by the glass controls that float over a video.
    static let height: CGFloat = 44

    init(systemImage: String, title: String? = nil, label: String, style: GlassButton.GlassButtonStyle = .secondary, isDisabled: Bool = false, perform action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.title = title
        self.label = label
        self.style = style
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            GlassIconLabel(systemImage: systemImage, title: title, style: style)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.4 : 1)
        .accessibilityLabel(label)
    }
}

/// The look of a `GlassIconButton`, for controls such as menus and pickers that bring their own button.
struct GlassIconLabel: View {
    let systemImage: String
    var title: String? = nil
    var style: GlassButton.GlassButtonStyle = .secondary

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .customFont(.body, weight: .semibold)

            if let title {
                Text(title)
                    .customFont(.subheadline, weight: .semibold)
                    .lineLimit(1)
            }
        }
        .foregroundStyle(style == .prominent ? .white : .primary)
        .padding(.horizontal, title == nil ? 0 : 16)
        .frame(minWidth: GlassIconButton.height)
        .frame(height: GlassIconButton.height)
        .contentShape(.capsule)
        .glassEffect(style == .prominent ? .regular.tint(.accentColor).interactive() : .regular.interactive(), in: .capsule)
        .fixedSize()
    }
}
