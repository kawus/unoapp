import SwiftUI

/// Horizontal bar of lighting preset buttons with metering grid toggle
struct PresetBar: View {
    @Binding var selectedPreset: CameraPreset
    let showMeteringGrid: Bool
    let onPresetSelected: (CameraPreset) -> Void
    let onGridToggle: () -> Void

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

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 1, height: 30)
                .padding(.horizontal, 4)

            // Metering grid toggle button
            GridToggleButton(
                isActive: showMeteringGrid,
                action: onGridToggle
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

/// Toggle button for metering grid overlay
struct GridToggleButton: View {
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "square.grid.3x3")
                .font(.system(size: 20))
                .frame(width: 44, height: 44)
                .background(isActive ? Color.white.opacity(0.25) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .foregroundStyle(isActive ? .white : .white.opacity(0.7))
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
                showMeteringGrid: false,
                onPresetSelected: { _ in },
                onGridToggle: {}
            )
            Spacer()
        }
    }
}
