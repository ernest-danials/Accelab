//
//  SelectExperimentView.swift
//  Accelab
//

import SwiftUI
import SwiftData

/// The home screen, where the experiment is chosen. The method is chosen next, on `SelectMethodView`.
struct SelectExperimentView: View {
    @Environment(MethodManager.self) private var methodManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isShowingSettingsView: Bool = false
    @State private var isShowingPastRunsView: Bool = false

    var body: some View {
        @Bindable var methodManager = methodManager

        ZStack {
            StepTitleView(title: "Accelab", subtitle: "Welcome to", description: methodManager.experiment.description, isProminent: true)

            ExperimentDrawing(experiment: methodManager.experiment)

            GlassIconButton(systemImage: "clock.arrow.circlepath", title: "Past Runs", label: "Past Runs") {
                self.isShowingPastRunsView = true
            }
            .alignView(to: .trailing)
            .alignViewVertically(to: .top)
            .padding()

            GlassIconButton(systemImage: "gearshape", label: "Settings") {
                self.isShowingSettingsView = true
            }
            .alignView(to: .leading)
            .alignViewVertically(to: .bottom)
            .padding()

            // In the row of the buttons, so choosing adds nothing to the screen's height. A segmented
            // control rather than more buttons: it is one setting with three values. Wide enough for its
            // three names at this size, and still clear of Settings and Next on the smallest screen.
            Picker("Experiment", selection: $methodManager.experiment.animation(reduceMotion ? nil : ExperimentDrawing.changeAnimation)) {
                ForEach(Experiment.allCases) { experiment in
                    Text(experiment.rawValue)
                        .tag(experiment)
                }
            }
            .pickerStyle(.segmented)
            .controlSize(.large)
            .frame(width: 390, height: GlassIconButton.height)
            .sensoryFeedback(.selection, trigger: methodManager.experiment)
            .alignViewVertically(to: .bottom)
            .padding()

            GlassIconButton(systemImage: "arrow.forward", title: "Next", label: "Next", style: .prominent) {
                methodManager.show(.methods)
            }
            .alignView(to: .trailing)
            .alignViewVertically(to: .bottom)
            .padding()
        }
        .fullScreenCover(isPresented: $isShowingSettingsView) {
            SettingsView()
        }
        .fullScreenCover(isPresented: $isShowingPastRunsView, onDismiss: removePastRunExports) {
            PastRunsView()
        }
    }

    /// Removes the files a past run wrote for sharing. No run is in progress on this screen, so nothing else owns them.
    private func removePastRunExports() {
        CSVExporter.removeTempFiles()
        RunMediaExporter.removeTempFiles()
    }
}

#Preview {
    SelectExperimentView()
        .environment(MethodManager())
        .modelContainer(for: SavedRun.self, inMemory: true)
}
