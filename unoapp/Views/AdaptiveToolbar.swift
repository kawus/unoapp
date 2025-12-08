//
//  AdaptiveToolbar.swift
//  unoapp
//
//  Toolbar that adapts position based on device orientation.
//  Portrait: Bottom of screen
//  Landscape: Right edge (like native iOS Camera app)
//

import SwiftUI

/// Adaptive toolbar that positions record button centered with thumbnail and grid toggle on sides
struct AdaptiveToolbar: View {

    let isLandscape: Bool
    let thumbnail: UIImage?
    let isRecording: Bool
    let showMeteringGrid: Bool
    let onThumbnailTap: () -> Void
    let onRecordTap: () -> Void
    let onGridToggle: () -> Void

    var body: some View {
        if isLandscape {
            // Landscape: controls on right edge
            // Record button centered vertically, thumbnail at top, grid at bottom
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
                }
                .padding(.trailing, 30)
                .padding(.vertical, 40)
            }
        } else {
            // Portrait: controls at bottom
            // Record button centered horizontally, thumbnail on left, grid on right
            VStack {
                Spacer()
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
struct GridToggleButton: View {
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "square.grid.3x3")
                .font(.system(size: 20))
                .frame(width: 44, height: 44)
                .background(isActive ? Color.white.opacity(0.25) : Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .foregroundStyle(isActive ? .white : .white.opacity(0.7))
        .buttonStyle(.plain)
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
            onThumbnailTap: {},
            onRecordTap: {},
            onGridToggle: {}
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
            onThumbnailTap: {},
            onRecordTap: {},
            onGridToggle: {}
        )
    }
}
