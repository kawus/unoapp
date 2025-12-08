import SwiftUI

/// Horizontal bar of lighting preset buttons
struct PresetBar: View {
    @Binding var selectedPreset: CameraPreset
    let onPresetSelected: (CameraPreset) -> Void

    var body: some View {
        HStack(spacing: 8) {
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
struct PresetButton: View {
    let preset: CameraPreset
    let isSelected: Bool
    let action: () -> Void

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
        }
        .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
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
