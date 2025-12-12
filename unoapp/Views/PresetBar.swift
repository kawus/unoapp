import SwiftUI

/// Horizontal bar of lighting preset buttons with aspect ratio and Max FOV toggles
struct PresetBar: View {
    @Binding var selectedPreset: CameraPreset
    let aspectRatio: AspectRatio
    let maxFOVEnabled: Bool
    let isRecording: Bool
    let onPresetSelected: (CameraPreset) -> Void
    let onAspectRatioToggle: () -> Void
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

            // Divider between presets and toggles
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 1, height: 28)
                .padding(.horizontal, 2)

            // Aspect ratio toggle (16:9 / 4:3)
            AspectRatioButton(
                aspectRatio: aspectRatio,
                isDisabled: isRecording,
                action: onAspectRatioToggle
            )

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

/// Aspect ratio toggle button (16:9 / 4:3)
/// 4:3 captures more of the circular fisheye projection
struct AspectRatioButton: View {
    let aspectRatio: AspectRatio
    let isDisabled: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: aspectRatio == .fourByThree ? "rectangle.portrait" : "rectangle")
                    .font(.system(size: 16))
                Text(aspectRatio.label)
                    .font(.system(size: 9))
                    .fontWeight(.medium)
            }
            .frame(minWidth: 40)
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
            .background(aspectRatio == .fourByThree ? Color.blue.opacity(0.6) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .scaleEffect(isPressed ? 0.92 : 1.0)
        }
        .foregroundStyle(isDisabled ? .white.opacity(0.4) : (aspectRatio == .fourByThree ? .white : .white.opacity(0.7)))
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !isDisabled { isPressed = true } }
                .onEnded { _ in isPressed = false }
        )
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: aspectRatio)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: aspectRatio)
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
                aspectRatio: .sixteenByNine,
                maxFOVEnabled: false,
                isRecording: false,
                onPresetSelected: { _ in },
                onAspectRatioToggle: {},
                onMaxFOVToggle: {}
            )
            Spacer()
        }
    }
}

#Preview("4:3 + Max FOV Enabled") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            PresetBar(
                selectedPreset: .constant(.sunny),
                aspectRatio: .fourByThree,
                maxFOVEnabled: true,
                isRecording: false,
                onPresetSelected: { _ in },
                onAspectRatioToggle: {},
                onMaxFOVToggle: {}
            )
            Spacer()
        }
    }
}
