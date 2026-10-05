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

    var body: some View {
        // Rows rather than fixed positions, and the tips scroll, so nothing is cut off on a smaller screen.
        VStack(alignment: .leading, spacing: 0) {
            StepTitleView(title: CameraMethodStep.setup.title, subtitle: CameraMethodStep.setup.subtitle, description: CameraMethodStep.setup.description, isProminent: false, isInline: true)
                .padding([.top, .horizontal], 30)
                .padding(.bottom, 10)

            ScrollView {
                GlassEffectContainer {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 10, alignment: .top)], alignment: .leading, spacing: 10) {
                        ForEach(Self.tips) { tip in
                            tipCard(for: tip)
                        }
                    }
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 6)
            }
            .scrollBounceBehavior(.basedOnSize)

            GlassEffectContainer {
                HStack {
                    GlassIconButton(systemImage: "chevron.backward", label: "Back", perform: onBack)

                    GlassIconButton(systemImage: "arrow.forward", label: "Continue", style: .prominent, perform: onContinue)
                }
            }
            .alignView(to: .trailing)
            .padding()
        }
    }

    private func tipCard(for tip: Tip) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: tip.systemImage)
                .customFont(.title3, weight: .medium)
                .foregroundStyle(Method.camera.color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(tip.title)
                    .customFont(.subheadline, weight: .bold)

                Text(tip.detail)
                    .customFont(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
    }
}
