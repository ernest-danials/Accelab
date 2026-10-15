//
//  SelectMethodView.swift
//  Accelab
//
//  Created by Myung Joon Kang on 2026-10-04.
//

import SwiftUI

/// Where the method is chosen for the experiment chosen on the home screen. Both methods are side by side,
/// each with the data it gives, since for some experiments they measure quite different things.
struct SelectMethodView: View {
    @Environment(MethodManager.self) private var methodManager

    var body: some View {
        let experiment = methodManager.experiment

        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading) {
                StepTitleView(title: experiment.rawValue, subtitle: "Choose a method for", description: experiment.methodChoiceHint, isProminent: true, isInline: true)
                    // Where the other screens' titles are: 30 from the edges, of which `padding()` gives 16.
                    .padding([.top, .leading], 14)

                Spacer(minLength: 16)

                GlassIconButton(systemImage: "chevron.backward", label: "Back") {
                    methodManager.show(.home)
                }
            }
            .frame(maxWidth: 220, maxHeight: .infinity, alignment: .leading)

            ForEach(Method.allCases) { method in
                MethodCard(experiment: experiment, method: method) {
                    methodManager.show(.method(method))
                }
            }
        }
        .padding()
    }
}

/// One method's card: what is done with the iPhone, the columns of data it gives, and the graph they are
/// for. A method that can't do the experiment keeps its card, dimmed, with the reason in place of the data.
private struct MethodCard: View {
    let experiment: Experiment
    let method: Method
    let onChoose: () -> Void

    private static let cornerRadius: CGFloat = 28

    private var isAvailable: Bool {
        experiment.supports(method)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            // Scrolls only on a screen too short for all of it, keeping the button in place below.
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(experiment.setup(for: method))
                        .customFont(.footnote)
                        .foregroundStyle(.secondary)

                    if let data = experiment.emptyData(for: method) {
                        columns(of: data)
                    }

                    if let graph = experiment.graph(for: method) {
                        Label(graph, systemImage: "chart.xyaxis.line")
                            .customFont(.footnote)
                    }

                    if isAvailable {
                        Label(note, systemImage: noteImageName)
                            .customFont(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)

            if isAvailable {
                GlassButton(text: "Use \(method.rawValue)", textFont: .headline, perform: onChoose)
                    .tint(method.color)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(method.color.opacity(0.14), in: .rect(cornerRadius: Self.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: Self.cornerRadius)
                .strokeBorder(method.color.opacity(0.35), lineWidth: 1)
        }
        .opacity(isAvailable ? 1 : 0.5)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: method.imageName)
                .customFont(.title3, weight: .medium)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(method.color)
                .frame(width: 44, height: 44)
                // No glass on a dimmed card: glass distorts when it is faded.
                .glassEffect(isAvailable ? .regular : .identity, in: .circle)

            VStack(alignment: .leading, spacing: 0) {
                Text(method.rawValue)
                    .customFont(.title2, weight: .bold)

                // Under the name rather than beside it, which a narrow card has no room for.
                if !isAvailable {
                    Text("Not Available")
                        .customFont(.caption, weight: .medium)
                        .foregroundStyle(.secondary)
                } else if experiment.recommendedMethod == method {
                    Text("Recommended")
                        .customFont(.caption, weight: .medium)
                        .foregroundStyle(method.color)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// The columns of the table, CSV and Desmos export, under the same headings as the table.
    private func columns(of data: RunData) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("You Get")
                .customFont(.caption, weight: .semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            // Each heading kept on one line, so the list only breaks between them.
            Text(DataTableView.columnHeadings(for: data).map { $0.replacingOccurrences(of: " ", with: "\u{00A0}") }.joined(separator: "  ·  "))
                .customFont(.subheadline, weight: .medium)
        }
    }

    /// What else comes with the method.
    private var note: String {
        switch method {
        case .camera:
            return "Also gives you the video and a photo of every tracked point."
        case .sensor:
            return "Turn off Orientation Lock before you start."
        }
    }

    private var noteImageName: String {
        switch method {
        case .camera:
            return "photo.on.rectangle"
        case .sensor:
            return "lock.rotation"
        }
    }
}

#Preview("Circular Motion") {
    let methodManager = MethodManager()
    methodManager.experiment = .circularMotion

    return SelectMethodView()
        .environment(methodManager)
}

#Preview("Projectile") {
    let methodManager = MethodManager()
    methodManager.experiment = .projectile

    return SelectMethodView()
        .environment(methodManager)
}
