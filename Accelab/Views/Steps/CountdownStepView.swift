//
//  CountdownStepView.swift
//  Accelab
//

import SwiftUI

struct CountdownStepView: View {
    let onCancel: () -> Void
    /// Called when the countdown reaches zero; not called if the countdown is cancelled.
    let onFinished: () -> Void

    @State private var countdownValue: Int = CountdownStepView.countdownSeconds

    private static let countdownSeconds = 3

    var body: some View {
        ZStack {
            Text("\(countdownValue)")
                .font(.system(size: 120, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: true))
                .offset(y: 15)

            GlassButton(text: "Cancel", style: .secondary, perform: onCancel)
                .alignView(to: .trailing)
                .alignViewVertically(to: .bottom)
                .padding()
        }
        .task {
            // Cancelled automatically when the step changes and this view disappears.
            self.countdownValue = Self.countdownSeconds

            while self.countdownValue > 0 {
                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    return
                }

                withAnimation { self.countdownValue -= 1 }
            }

            onFinished()
        }
    }
}
