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
    private static let tips: [Tip] = [
        Tip(systemImage: "iphone.gen3", title: "Keep it still", detail: "Prop your iPhone so it can't move. Don't hold it."),
        Tip(systemImage: "viewfinder", title: "Face the track", detail: "Square-on, level with the track, aimed at its middle."),
        Tip(systemImage: "arrow.up.left.and.arrow.down.right", title: "Stand back", detail: "Fit the whole run in the shot with room to spare."),
        Tip(systemImage: "ruler", title: "Show a known length", detail: "The track's own ruler, or a metre stick lying on it. You'll mark it after recording."),
        Tip(systemImage: "sun.max", title: "Use good light", detail: "A bright room keeps the moving cart sharp."),
        Tip(systemImage: "rectangle.dashed", title: "Keep the view clear", detail: "Nothing should pass between the camera and the cart.")
    ]

    var body: some View {
        ZStack {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20, alignment: .topLeading), count: 3), alignment: .leading, spacing: 14) {
                ForEach(Self.tips) { tip in
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
                }
            }
            .padding(.horizontal, 30)
            .offset(y: 20)

            HStack {
                GlassButton(text: "Back", style: .secondary, perform: onBack)

                GlassButton(text: "Continue", perform: onContinue)
            }
            .alignView(to: .trailing)
            .alignViewVertically(to: .bottom)
            .padding()
        }
    }
}
