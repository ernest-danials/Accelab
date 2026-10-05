//
//  StepTitleView.swift
//  Accelab
//

import SwiftUI

/// The title block of a step of a method, drawn in the top-leading corner unless it is inline.
struct StepTitleView: View {
    let title: String
    let subtitle: String
    let description: String
    /// Uses the larger home-screen styling, as on a method's idle step.
    let isProminent: Bool
    /// Leaves positioning to the step, for steps that lay themselves out around the title.
    var isInline: Bool = false

    var body: some View {
        if isInline {
            content
        } else {
            content
                .alignView(to: .leading)
                .alignViewVertically(to: .top)
                .padding(30)
        }
    }

    private var content: some View {
        VStack(alignment: .leading) {
            if !subtitle.isEmpty {
                Text(subtitle)
                    .customFont(isProminent ? .title3 : .subheadline)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }

            Text(title)
                .customFont(isProminent ? .largeTitle : .title3, weight: .bold)
                .contentTransition(.numericText())

            if !description.isEmpty {
                Text(description)
                    .customFont(.footnote)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                    .frame(maxWidth: isProminent ? 280 : nil, alignment: .leading)
            }
        }
    }
}
