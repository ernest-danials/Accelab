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
        Button {
            if style == .prominent { Haptics.prominentTap() } else { Haptics.tap() }
            action()
        } label: {
            GlassIconLabel(systemImage: systemImage, title: title, style: style)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityLabel(label)
    }
}

/// The look of a `GlassIconButton`, for controls such as menus and pickers that bring their own button.
struct GlassIconLabel: View {
    let systemImage: String
    var title: String? = nil
    var style: GlassButton.GlassButtonStyle = .secondary

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isHiddenWithChrome) private var isHiddenWithChrome

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .customFont(.body, weight: .semibold)
                .contentTransition(.symbolEffect(.replace))

            if let title {
                Text(title)
                    .customFont(.subheadline, weight: .semibold)
                    .lineLimit(1)
                    .contentTransition(.numericText())
            }
        }
        // Disabled is shown in the content and the glass itself rather than with opacity, which glass
        // inside a `GlassEffectContainer` ignores.
        .foregroundStyle(isEnabled ? (style == .prominent ? AnyShapeStyle(.white) : AnyShapeStyle(.primary)) : AnyShapeStyle(.tertiary))
        .opacity(isHiddenWithChrome ? 0 : 1)
        .padding(.horizontal, title == nil ? 0 : 16)
        .frame(minWidth: GlassIconButton.height)
        .frame(height: GlassIconButton.height)
        .contentShape(.capsule)
        .glassEffect(glass, in: .capsule)
        .fixedSize()
    }

    /// Tinted and responsive to touch only while enabled, so a disabled button neither looks nor feels pressable.
    private var glass: Glass {
        guard !isHiddenWithChrome else { return .identity }
        guard isEnabled else { return .regular }
        return style == .prominent ? .regular.tint(.accentColor).interactive() : .regular.interactive()
    }
}
