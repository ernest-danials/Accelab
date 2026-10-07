//
//  LevelStepView.swift
//  Accelab
//

import SwiftUI

/// Levels the phone before a projectile is filmed. A projectile's x and y are the picture's own axes, so
/// the picture's long edge has to be the real horizontal; a track's direction is fitted from the points
/// instead, which is why a cart on a track has no such step.
///
/// The reading is the tilt of the phone's long edge from horizontal, the same one `DetermineAngleStepView`
/// compares with the track's slope, here compared with zero. Leaning the phone back against its prop
/// doesn't change it.
struct LevelStepView: View {
    @Environment(AngleManager.self) private var angleManager: AngleManager
    @Environment(\.colorScheme) private var colorScheme

    let marginOfErrorForAngle: Double
    let currentDeviceOrientation: UIDeviceOrientation?
    let isLevel: Bool
    let isShowingDeviceOrientationNotValidDisclaimer: Bool
    let onBack: () -> Void
    /// For a video that was filmed earlier, where there is nothing left to level.
    let onSkip: () -> Void
    let onContinue: () -> Void

    /// How long the phone must stay level before the step continues on its own.
    private static let holdSeconds = 3

    /// Seconds left of the current hold; `nil` while the phone isn't level.
    @State private var holdCountdownValue: Int? = nil

    var body: some View {
        ZStack {
            HStack {
                Text("\(angleManager.currentAngle, specifier: "%.2f")°")
                    .customFont(.largeTitle, weight: .bold)
                    .contentTransition(.numericText(value: angleManager.currentAngle))
                    .frame(width: 130)
                    .minimumScaleFactor(0.7)

                ZStack {
                    // Which way the horizon leans on screen, worked out as on the angle step.
                    let isObtuse = angleManager.rawAngle > 90
                    let isLeft = (currentDeviceOrientation == .some(.landscapeLeft))
                    let signedAngle = (isLeft != isObtuse) ? angleManager.currentAngle : -angleManager.currentAngle

                    // The real horizontal, which turns against the phone as the phone is tilted.
                    Capsule()
                        .fill(Color.secondary)
                        .frame(width: 250, height: 4)
                        .rotationEffect(.degrees(signedAngle))
                        .animation(.easeInOut(duration: 0.15), value: angleManager.currentAngle)

                    // The phone's own long edge.
                    Capsule()
                        .fill(isLevel ? (colorScheme == .dark ? .white : .black) : .accentColor)
                        .frame(width: 250, height: 4)
                }
            }
            .offset(y: 20)

            VStack(alignment: .leading) {
                Label("Margin of Error: \(marginOfErrorForAngle, specifier: "%.2f")°", systemImage: "plusminus")
                    .customFont(.subheadline, weight: .medium)

                Text("You can change the margin of error in the settings menu.")
                    .customFont(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .alignView(to: .leading)
            .alignViewVertically(to: .bottom)

            if let holdCountdownValue {
                VStack(spacing: 0) {
                    Text("\(holdCountdownValue)")
                        .font(.system(size: 100, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText(countsDown: true))

                    Text("Hold Steady")
                        .customFont(.headline, weight: .bold)
                }
                .padding(.horizontal, 30)
                .alignView(to: .trailing)
                .alignViewVertically(to: .top)
                .transition(.blurReplace)
            }

            GlassEffectContainer {
                HStack {
                    GlassIconButton(systemImage: "chevron.backward", label: "Back", perform: onBack)

                    GlassIconButton(systemImage: "forward.end", title: "Skip", label: "Skip", perform: onSkip)

                    GlassIconButton(systemImage: "arrow.forward", label: "Continue", style: .prominent, isDisabled: !isLevel, perform: onContinue)
                }
                .alignView(to: .trailing)
                .alignViewVertically(to: .bottom)
                .padding()
            }
        }
        // Restarts whenever the phone becomes level or stops being level, so only an unbroken hold continues.
        .task(id: isLevel) {
            withAnimation {
                self.holdCountdownValue = isLevel ? Self.holdSeconds : nil
            }

            guard isLevel else { return }

            // Felt without looking, while both hands are on the phone.
            Haptics.tick()

            while let value = self.holdCountdownValue, value > 0 {
                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    return
                }

                withAnimation { self.holdCountdownValue = value - 1 }
                if value > 1 { Haptics.tick() }
            }

            Haptics.success()
            onContinue()
        }
        .overlay {
            if isShowingDeviceOrientationNotValidDisclaimer {
                ContentUnavailableView("iPhone isn't upright", systemImage: "iphone.badge.exclamationmark", description: Text("Accelab can't tell whether your iPhone is level while it is lying flat. Stand it upright in landscape to continue."))
                    .frame(width: 350)
                    .alignView(to: .center)
                    .background(Material.ultraThin)
            }
        }
    }
}
