//
//  AdaptiveToolbar.swift
//  unoapp
//
//  Toolbar that adapts position based on device orientation.
//  Portrait: Bottom of screen
//  Landscape: Right edge (like native iOS Camera app)
//

import SwiftUI

/// Adaptive toolbar that positions record button centered with thumbnail, lens selector, and grid toggle
struct AdaptiveToolbar: View {

    let isLandscape: Bool
    let thumbnail: UIImage?
    let isRecording: Bool
    let showMeteringGrid: Bool
    let selectedLens: CameraLens
    let onThumbnailTap: () -> Void
    let onRecordTap: () -> Void
    let onGridToggle: () -> Void
    let onLensChange: (CameraLens) -> Void

    var body: some View {
        if isLandscape {
            // Landscape: controls on right edge
            // Record button centered vertically, thumbnail at top, grid at bottom
            // Lens selector to the LEFT of record button (which means "below" in the VStack due to rotation)
            HStack {
                Spacer()
                ZStack {
                    // Record button - centered
                    RecordButton(isRecording: isRecording, action: onRecordTap)

                    // Thumbnail (top) and Grid toggle (bottom)
                    VStack {
                        ThumbnailButton(thumbnail: thumbnail, action: onThumbnailTap)
                        Spacer()
                        GridToggleButton(isActive: showMeteringGrid, action: onGridToggle)
                    }

                    // Lens selector - offset BELOW record button (appears LEFT in landscape)
                    VStack {
                        LensSelectorView(
                            selectedLens: selectedLens,
                            isDisabled: isRecording,
                            onSelect: onLensChange
                        )
                        .padding(.top, 90)
                        Spacer()
                    }
                }
                .padding(.trailing, 30)
                .padding(.vertical, 40)
            }
        } else {
            // Portrait: controls at bottom
            // Record button centered horizontally, thumbnail on left, grid on right
            VStack {
                Spacer()
                // Lens selector - above the main toolbar row
                LensSelectorView(
                    selectedLens: selectedLens,
                    isDisabled: isRecording,
                    onSelect: onLensChange
                )
                .padding(.bottom, 16)

                ZStack {
                    // Record button - centered
                    RecordButton(isRecording: isRecording, action: onRecordTap)

                    // Thumbnail (left) and Grid toggle (right)
                    HStack {
                        ThumbnailButton(thumbnail: thumbnail, action: onThumbnailTap)
                        Spacer()
                        GridToggleButton(isActive: showMeteringGrid, action: onGridToggle)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Grid Toggle Button

/// Toggle button for metering grid overlay (44x44pt to match ThumbnailButton)
/// Includes press feedback and smooth toggle animation
struct GridToggleButton: View {
    let isActive: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "square.grid.3x3")
                .font(.system(size: 20))
                .frame(width: 44, height: 44)
                .background(isActive ? Color.white.opacity(0.25) : Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .foregroundStyle(isActive ? .white : .white.opacity(0.7))
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .animation(.easeOut(duration: 0.1), value: isPressed)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isActive)
    }
}

#Preview("Portrait") {
    ZStack {
        Color.black.ignoresSafeArea()
        AdaptiveToolbar(
            isLandscape: false,
            thumbnail: nil,
            isRecording: false,
            showMeteringGrid: false,
            selectedLens: .ultraWide,
            onThumbnailTap: {},
            onRecordTap: {},
            onGridToggle: {},
            onLensChange: { _ in }
        )
    }
}

#Preview("Landscape", traits: .landscapeLeft) {
    ZStack {
        Color.black.ignoresSafeArea()
        AdaptiveToolbar(
            isLandscape: true,
            thumbnail: nil,
            isRecording: false,
            showMeteringGrid: true,
            selectedLens: .wide,
            onThumbnailTap: {},
            onRecordTap: {},
            onGridToggle: {},
            onLensChange: { _ in }
        )
    }
}
