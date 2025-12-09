import SwiftUI

/// Horizontal bar of lighting preset buttons
struct PresetBar: View {
    @Binding var selectedPreset: CameraPreset
    let onPresetSelected: (CameraPreset) -> Void

    var body: some View {
        HStack(spacing: 8) {
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
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
            VStack(spacing: 4) {
                Image(systemName: preset.icon)
                    .font(.system(size: 20))
                Text(preset.label)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .frame(minWidth: 60)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.white.opacity(0.25) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
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

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            PresetBar(
                selectedPreset: .constant(.sunny),
                onPresetSelected: { _ in }
            )
            Spacer()
        }
    }
}
