//
//  StepTitleView.swift
//  Accelab
//

import SwiftUI

/// The title block drawn in the top-leading corner of every step of a method.
struct StepTitleView: View {
    let title: String
    let subtitle: String
    let description: String
    /// Uses the larger home-screen styling, as on a method's idle step.
    let isProminent: Bool

    var body: some View {
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
        .alignView(to: .leading)
        .alignViewVertically(to: .top)
        .padding(30)
    }
}
