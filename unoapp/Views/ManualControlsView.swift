import SwiftUI

/// Stepper controls for manual camera settings
/// Shows current values so user can note them for preset tuning
struct ManualControlsView: View {
    @Binding var settings: CameraSettings
    let onSettingsChanged: (CameraSettings) -> Void

    var body: some View {
        VStack(spacing: 8) {
            // ISO Control
            SettingRow(
                label: "ISO",
                value: settings.isoDisplay,
                onDecrease: {
                    settings.adjustISO(by: -1)
                    onSettingsChanged(settings)
                },
                onIncrease: {
                    settings.adjustISO(by: 1)
                    onSettingsChanged(settings)
                },
                canDecrease: settings.iso > CameraSettings.isoRange.lowerBound,
                canIncrease: settings.iso < CameraSettings.isoRange.upperBound
            )

            // Exposure Bias Control
            SettingRow(
                label: "EXP",
                value: settings.exposureDisplay,
                onDecrease: {
                    settings.adjustExposure(by: -1)
                    onSettingsChanged(settings)
                },
                onIncrease: {
                    settings.adjustExposure(by: 1)
                    onSettingsChanged(settings)
                },
                canDecrease: settings.exposureBias > CameraSettings.exposureRange.lowerBound,
                canIncrease: settings.exposureBias < CameraSettings.exposureRange.upperBound
            )

            // White Balance Control
            SettingRow(
                label: "WB",
                value: settings.whiteBalanceDisplay,
                onDecrease: {
                    settings.adjustWhiteBalance(by: -1)
                    onSettingsChanged(settings)
                },
                onIncrease: {
                    settings.adjustWhiteBalance(by: 1)
                    onSettingsChanged(settings)
                },
                canDecrease: settings.whiteBalance > CameraSettings.whiteBalanceRange.lowerBound,
                canIncrease: settings.whiteBalance < CameraSettings.whiteBalanceRange.upperBound
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

/// Single row: label, minus button, value, plus button
struct SettingRow: View {
    let label: String
    let value: String
    let onDecrease: () -> Void
    let onIncrease: () -> Void
    let canDecrease: Bool
    let canIncrease: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Label
            Text(label)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 40, alignment: .leading)

            Spacer()

            // Minus button
            StepperButton(
                systemName: "minus",
                action: onDecrease,
                isEnabled: canDecrease
            )

            // Current value (prominent for noting down)
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .frame(minWidth: 80)

            // Plus button
            StepperButton(
                systemName: "plus",
                action: onIncrease,
                isEnabled: canIncrease
            )
        }
    }
}

/// Circular stepper button
struct StepperButton: View {
    let systemName: String
    let action: () -> Void
    let isEnabled: Bool

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(isEnabled ? .white : .white.opacity(0.3))
                .frame(width: 36, height: 36)
                .background(isEnabled ? Color.white.opacity(0.2) : Color.white.opacity(0.05))
                .clipShape(Circle())
        }
        .disabled(!isEnabled)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            ManualControlsView(
                settings: .constant(.defaultManual),
                onSettingsChanged: { _ in }
            )
            Spacer()
        }
    }
}
