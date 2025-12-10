//
//  LensSelectorView.swift
//  unoapp
//
//  Compact lens selector for switching between ultrawide (0.5x) and wide (1x) cameras.
//  Positioned in the bottom toolbar alongside record button.
//

import SwiftUI

/// Compact segmented lens selector
/// Two side-by-side buttons showing 0.5 and 1 for lens options
struct LensSelectorView: View {

    let selectedLens: CameraLens
    let isDisabled: Bool
    let onSelect: (CameraLens) -> Void

    var body: some View {
        HStack(spacing: 2) {
            ForEach(CameraLens.allCases) { lens in
                LensButton(
                    lens: lens,
                    isSelected: lens == selectedLens,
                    isDisabled: isDisabled,
                    action: { onSelect(lens) }
                )
            }
        }
        .padding(3)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .opacity(isDisabled ? 0.5 : 1.0)
    }
}

// MARK: - Individual Lens Button

/// Single lens option button within the selector
private struct LensButton: View {

    let lens: CameraLens
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            if !isDisabled {
                // Haptic feedback on selection
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                action()
            }
        }) {
            Text(lens.label)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .frame(width: 36, height: 32)
                .background(isSelected ? Color.white.opacity(0.25) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .scaleEffect(isPressed ? 0.92 : 1.0)
        }
        .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isDisabled { isPressed = true }
                }
                .onEnded { _ in isPressed = false }
        )
        .animation(.easeOut(duration: 0.1), value: isPressed)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isSelected)
        .accessibilityLabel(lens.accessibilityLabel)
    }
}

// MARK: - Previews

#Preview("Ultrawide Selected") {
    ZStack {
        Color.black.ignoresSafeArea()
        LensSelectorView(
            selectedLens: .ultraWide,
            isDisabled: false,
            onSelect: { lens in print("Selected: \(lens)") }
        )
    }
}

#Preview("Wide Selected") {
    ZStack {
        Color.black.ignoresSafeArea()
        LensSelectorView(
            selectedLens: .wide,
            isDisabled: false,
            onSelect: { lens in print("Selected: \(lens)") }
        )
    }
}

#Preview("Disabled (Recording)") {
    ZStack {
        Color.black.ignoresSafeArea()
        LensSelectorView(
            selectedLens: .ultraWide,
            isDisabled: true,
            onSelect: { lens in print("Selected: \(lens)") }
        )
    }
}
