//
//  MeasuringStepView.swift
//  Accelab
//

import SwiftUI

struct MeasuringStepView: View {
    let splits: [DistanceSplit]
    /// Called once the user has agreed to discard the collected data.
    let onDiscard: () -> Void
    let onDone: () -> Void

    @State private var isShowingConfirmationDialogToGoBack: Bool = false

    var body: some View {
        ZStack {
            ScrollView(.horizontal) {
                LazyHStack {
                    ForEach(splits.reversed()) { split in
                        VStack(spacing: 15) {
                            Text("\(split.timeElapsed, specifier: "%.2f")")
                                .customFont(.title2, weight: .medium)

                            Text("\(split.displacement, specifier: "%.2f")")
                                .customFont(.title2, weight: .medium)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .safeAreaPadding(.horizontal, 30)
            .safeAreaPadding(.leading, 100)

            VStack(spacing: 15) {
                VStack {
                    Image(systemName: "stopwatch.fill")
                        .customFont(.title3, weight: .medium)

                    Text("Second")
                        .customFont(.footnote)
                }

                VStack {
                    Image(systemName: "ruler.fill")
                        .customFont(.title3, weight: .medium)

                    Text("Metre")
                        .customFont(.footnote)
                }
            }
            .padding()
            .glassEffect()
            .alignView(to: .leading)
            .padding(30)

            GlassEffectContainer {
                HStack {
                    GlassButton(text: "Back", style: .secondary) {
                        self.isShowingConfirmationDialogToGoBack = true
                    }
                    .confirmationDialog("This will reset all the collected data. Are you sure?", isPresented: $isShowingConfirmationDialogToGoBack, titleVisibility: .visible) {
                        Button("Yes, reset and go back", role: .destructive, action: onDiscard)
                    }

                    GlassButton(text: "Done", isDisabled: splits.isEmpty, perform: onDone)
                }
                .alignView(to: .trailing)
                .alignViewVertically(to: .bottom)
                .padding()
            }
        }
    }
}
