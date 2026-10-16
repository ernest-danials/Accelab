//
//  MeasuringStepView.swift
//  Accelab
//

import SwiftUI

struct MeasuringStepView: View {
    /// The samples so far, newest shown first.
    let data: RunData
    /// Called once the user has agreed to discard the collected data.
    let onDiscard: () -> Void
    let onDone: () -> Void

    @State private var isShowingConfirmationDialogToGoBack: Bool = false

    /// One quantity of the samples: its symbol and unit in the legend, and its value in each column.
    private struct Quantity {
        let systemImage: String
        let unit: String
        let value: (Int) -> Double
    }

    var body: some View {
        ZStack {
            ScrollView(.horizontal) {
                LazyHStack {
                    ForEach((0..<data.count).reversed(), id: \.self) { index in
                        VStack(spacing: 15) {
                            ForEach(quantities.indices, id: \.self) { quantity in
                                Text("\(quantities[quantity].value(index), specifier: "%.2f")")
                                    .customFont(.title2, weight: .medium)
                            }
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .safeAreaPadding(.horizontal, 30)
            .safeAreaPadding(.leading, 100)

            VStack(spacing: 15) {
                ForEach(quantities.indices, id: \.self) { quantity in
                    VStack {
                        Image(systemName: quantities[quantity].systemImage)
                            .customFont(.title3, weight: .medium)

                        Text(quantities[quantity].unit)
                            .customFont(.footnote)
                    }
                }
            }
            .padding()
            .glassEffect()
            .alignView(to: .leading)
            .padding(30)

            GlassEffectContainer {
                HStack {
                    GlassIconButton(systemImage: "chevron.backward", label: "Back") {
                        self.isShowingConfirmationDialogToGoBack = true
                    }
                    .confirmationDialog("This will reset all the collected data. Are you sure?", isPresented: $isShowingConfirmationDialogToGoBack, titleVisibility: .visible) {
                        Button("Yes, reset and go back", role: .destructive, action: onDiscard)
                    }

                    GlassIconButton(systemImage: "checkmark", label: "Done", style: .prominent, isDisabled: data.isEmpty, perform: onDone)
                }
                .alignView(to: .trailing)
                .alignViewVertically(to: .bottom)
                .padding()
            }
        }
    }

    /// What each column shows, top to bottom: the time, then what was measured.
    private var quantities: [Quantity] {
        switch data {
        case .distance(let splits):
            return [Quantity(systemImage: "stopwatch.fill", unit: "Second", value: { splits[$0].timeElapsed }), Quantity(systemImage: "ruler.fill", unit: "Metre", value: { splits[$0].displacement })]
        case .position(let splits):
            // Not measured by this method, but shown the same way should it ever be.
            return [Quantity(systemImage: "stopwatch.fill", unit: "Second", value: { splits[$0].timeElapsed }), Quantity(systemImage: "arrow.right", unit: "x, m", value: { splits[$0].x }), Quantity(systemImage: "arrow.up", unit: "y, m", value: { splits[$0].y })]
        case .rotation(let splits):
            return [Quantity(systemImage: "stopwatch.fill", unit: "Second", value: { splits[$0].timeElapsed }), Quantity(systemImage: "gyroscope", unit: "rad/s", value: { splits[$0].angularVelocity }), Quantity(systemImage: "arrow.down.to.line", unit: "m/s²", value: { splits[$0].centripetalAcceleration })]
        case .circle(let splits):
            // Not measured by this method either, but shown the same way should it ever be.
            return [Quantity(systemImage: "stopwatch.fill", unit: "Second", value: { splits[$0].timeElapsed }), Quantity(systemImage: "angle", unit: "rad", value: { splits[$0].angle }), Quantity(systemImage: "circle", unit: "Metre", value: { splits[$0].radius })]
        }
    }
}
