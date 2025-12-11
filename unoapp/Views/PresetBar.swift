import SwiftUI

/// Horizontal bar of lighting preset buttons with Max FOV toggle
struct PresetBar: View {
    @Binding var selectedPreset: CameraPreset
    let maxFOVEnabled: Bool
    let isRecording: Bool
    let onPresetSelected: (CameraPreset) -> Void
    let onMaxFOVToggle: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            // Preset buttons
            ForEach(CameraPreset.allCases) { preset in
                PresetButton(
                    preset: preset,
                    isSelected: selectedPreset == preset,
                    action: {
                        selectedPreset = preset
                        onPresetSelected(preset)
                    }
                )
            }

            // Divider between presets and Max FOV
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 1, height: 28)
                .padding(.horizontal, 2)

            // Max FOV toggle
            MaxFOVButton(
                isEnabled: maxFOVEnabled,
                isDisabled: isRecording,
                action: onMaxFOVToggle
            )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }
}

/// Individual preset button with icon and label
/// Includes press feedback animation and smooth selection transition
struct PresetButton: View {
    let preset: CameraPreset
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: preset.icon)
                    .font(.system(size: 18))
                Text(preset.label)
                    .font(.system(size: 10))
                    .fontWeight(.medium)
            }
            .frame(minWidth: 50)
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(isSelected ? Color.white.opacity(0.25) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .scaleEffect(isPressed ? 0.92 : 1.0)
        }
        .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

/// Max FOV mode toggle button
/// When enabled, disables distortion correction for external fisheye lenses
struct MaxFOVButton: View {
    let isEnabled: Bool
    let isDisabled: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: "viewfinder.circle")
                    .font(.system(size: 18))
                Text("FOV")
                    .font(.system(size: 10))
                    .fontWeight(.medium)
            }
            .frame(minWidth: 44)
            .padding(.vertical, 6)
            .padding(.horizontal, 6)
            .background(isEnabled ? Color.orange.opacity(0.6) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .scaleEffect(isPressed ? 0.92 : 1.0)
        }
        .foregroundStyle(isDisabled ? .white.opacity(0.4) : (isEnabled ? .white : .white.opacity(0.7)))
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !isDisabled { isPressed = true } }
                .onEnded { _ in isPressed = false }
        )
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isEnabled)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isEnabled)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            PresetBar(
                selectedPreset: .constant(.sunny),
                maxFOVEnabled: false,
                isRecording: false,
                onPresetSelected: { _ in },
                onMaxFOVToggle: {}
            )
            Spacer()
        }
    }
}

#Preview("Max FOV Enabled") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            PresetBar(
                selectedPreset: .constant(.sunny),
                maxFOVEnabled: true,
                isRecording: false,
                onPresetSelected: { _ in },
                onMaxFOVToggle: {}
            )
            Spacer()
        }
    }
}
