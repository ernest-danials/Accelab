//
//  SetupStepView.swift
//  Accelab
//

import SwiftUI

struct SetupStepView: View {
    let onBack: () -> Void
    let onContinue: () -> Void

    private struct Tip: Identifiable {
        let systemImage: String
        let title: String
        let detail: String

        var id: String { title }
    }

    // How the clip is filmed decides how accurate the scale is, far more than the tracking does.
    // The reference object (a ruler or anything of known length) must be as far from the camera as the cart, or it gives the wrong scale.
    private static let tips: [Tip] = [
        Tip(systemImage: "iphone.gen3", title: "Keep it still", detail: "Prop your iPhone. Don't hold it."),
        Tip(systemImage: "viewfinder", title: "Face the track", detail: "Square-on and level with it."),
        Tip(systemImage: "arrow.up.left.and.arrow.down.right", title: "Stand back", detail: "Fit the whole run with room to spare."),
        Tip(systemImage: "ruler", title: "Include something to measure", detail: "Any object of known length works, at the same distance from the camera as the cart."),
        Tip(systemImage: "sun.max", title: "Use good light", detail: "A bright room keeps the cart sharp."),
        Tip(systemImage: "rectangle.dashed", title: "Keep the view clear", detail: "Nothing between camera and cart.")
    ]

    private static let tipsPerRow = 3
    /// How far a tip's text may shrink to fit its card.
    private static let minimumTextScale: CGFloat = 0.6

    var body: some View {
        // Rows rather than fixed positions. The tips share the height between the title and the buttons
        // equally, and their text shrinks to fit its card, so nothing is cut off on a smaller screen.
        VStack(alignment: .leading, spacing: 0) {
            StepTitleView(title: CameraMethodStep.setup.title, subtitle: CameraMethodStep.setup.subtitle, description: CameraMethodStep.setup.description, isProminent: false, isInline: true)
                .padding([.top, .horizontal], 30)
                .padding(.bottom, 10)

            GlassEffectContainer {
                VStack(spacing: 10) {
                    ForEach(Array(stride(from: 0, to: Self.tips.count, by: Self.tipsPerRow)), id: \.self) { start in
                        HStack(spacing: 10) {
                            ForEach(Self.tips[start..<min(start + Self.tipsPerRow, Self.tips.count)]) { tip in
                                tipCard(for: tip)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 30)
            .padding(.top, 6)

            GlassEffectContainer {
                HStack {
                    GlassIconButton(systemImage: "chevron.backward", label: "Back", perform: onBack)

                    GlassIconButton(systemImage: "arrow.forward", label: "Continue", style: .prominent, perform: onContinue)
                }
            }
            .alignView(to: .trailing)
            .padding()
        }
        // The cards are sized for ordinary text; much larger text would have to shrink too far to fit.
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
    }

    private func tipCard(for tip: Tip) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: tip.systemImage)
                .customFont(.title3, weight: .medium)
                .foregroundStyle(Method.camera.color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(tip.title)
                    .customFont(.subheadline, weight: .bold)
                    .minimumScaleFactor(Self.minimumTextScale)

                Text(tip.detail)
                    .customFont(.caption)
                    .foregroundStyle(.secondary)
                    .minimumScaleFactor(Self.minimumTextScale)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
    }
}
