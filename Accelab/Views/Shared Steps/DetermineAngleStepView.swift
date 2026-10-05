//
//  DetermineAngleStepView.swift
//  Accelab
//

import SwiftUI

struct DetermineAngleStepView: View {
    @Environment(AngleManager.self) private var angleManager: AngleManager
    @Environment(\.colorScheme) private var colorScheme

    let desiredAngle: Double
    let marginOfErrorForAngle: Double
    let currentDeviceOrientation: UIDeviceOrientation?
    let isAngleReadyToCapture: Bool
    let isShowingDeviceOrientationNotValidDisclaimer: Bool
    let onBack: () -> Void
    /// Called with the angle captured at the moment the user continues.
    let onContinue: (Double) -> Void

    /// How long the angle must stay within the margin before the step continues on its own.
    private static let holdSeconds = 3

    /// Seconds left of the current hold within the margin; `nil` while the angle is outside it.
    @State private var holdCountdownValue: Int? = nil

    /// Set once the phone has been held the other way round from the interface for a while. The interface
    /// normally turns with the phone, so this only lasts when Orientation Lock is stopping it.
    @State private var isOrientationLockSuspected: Bool = false

    /// A normal rotation is briefly out of step with the phone too, so the notice waits this long.
    private static let orientationLockNoticeDelay: TimeInterval = 2

    var body: some View {
        ZStack {
            HStack {
                Text("\(angleManager.currentAngle, specifier: "%.2f")°")
                    .customFont(.largeTitle, weight: .bold)
                    .contentTransition(.numericText(value: angleManager.currentAngle))
                    .frame(width: 130)
                    .minimumScaleFactor(0.7)

                ZStack {
                    let isObtuse = angleManager.rawAngle > 90
                    let isLeft = (currentDeviceOrientation == .some(.landscapeLeft))
                    let anchor: UnitPoint = (isLeft != isObtuse) ? .leading : .trailing
                    let signedAngle = (anchor == .leading) ? angleManager.currentAngle : -angleManager.currentAngle

                    // Rotating ground (0° baseline relative to device)
                    Capsule()
                        .fill(Color.secondary)
                        .frame(width: 250, height: 4)
                        .rotationEffect(.degrees(signedAngle), anchor: anchor)
                        .animation(.easeInOut(duration: 0.15), value: angleManager.currentAngle)

                    // Fixed reference line (horizontal)
                    Capsule()
                        .fill(isAngleReadyToCapture ? (colorScheme == .dark ? .white : .black) : .accentColor)
                        .frame(width: 250, height: 4)
                }
            }
            .offset(y: 20)

            VStack(alignment: .leading) {
                if isOrientationLockSuspected {
                    orientationLockNotice
                        .padding(.bottom, 4)
                        .transition(.blurReplace)
                }

                Label("Target Angle: \(desiredAngle, specifier: "%.2f")°", systemImage: "angle")
                    .customFont(.subheadline, weight: .medium)

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

                    GlassIconButton(systemImage: "arrow.forward", label: "Continue", style: .prominent, isDisabled: !isAngleReadyToCapture) {
                        onContinue(angleManager.currentAngle)
                    }
                }
                .alignView(to: .trailing)
                .alignViewVertically(to: .bottom)
                .padding()
            }
        }
        // Restarts whenever the angle enters or leaves the margin, so only an unbroken hold continues.
        .task(id: isAngleReadyToCapture) {
            withAnimation {
                self.holdCountdownValue = isAngleReadyToCapture ? Self.holdSeconds : nil
            }

            guard isAngleReadyToCapture else { return }

            // Felt without looking, while both hands are on the track.
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
            onContinue(angleManager.currentAngle)
        }
        // The angle itself is unaffected by an upside-down interface, so this only informs; nothing is blocked.
        .task(id: isInterfaceUpsideDown) {
            guard isInterfaceUpsideDown else {
                withAnimation { self.isOrientationLockSuspected = false }
                return
            }

            try? await Task.sleep(for: .seconds(Self.orientationLockNoticeDelay))
            guard !Task.isCancelled else { return }

            withAnimation { self.isOrientationLockSuspected = true }
            Haptics.warning()
        }
        .overlay {
            if isShowingDeviceOrientationNotValidDisclaimer {
                ContentUnavailableView("iPhone isn't upright", systemImage: "iphone.badge.exclamationmark", description: Text("Accelab can't measure the angle while your iPhone is lying flat. Hold it upright in landscape to continue."))
                    .frame(width: 350)
                    .alignView(to: .center)
                    .background(Material.ultraThin)
            }
        }
    }

    /// `true` while the interface is drawn the other way up from how the phone is being held.
    private var isInterfaceUpsideDown: Bool {
        guard let physicalSide = angleManager.physicalLandscapeSide, let currentDeviceOrientation else { return false }
        return physicalSide != currentDeviceOrientation
    }

    private var orientationLockNotice: some View {
        Label("Screen upside down? Turn off Orientation Lock in Control Center.", systemImage: "lock.rotation")
            .customFont(.footnote, weight: .medium)
            .foregroundStyle(.yellow)
            // Turned the right way up for whoever is reading it, since everything else on screen is upside
            // down to them. Only the text is turned: a capsule looks the same either way, and glass loses
            // its shape when it is rotated.
            .rotationEffect(.degrees(180))
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .glassEffect(.regular, in: .capsule)
    }
}
