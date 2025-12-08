//
//  AdaptiveToolbar.swift
//  unoapp
//
//  Toolbar that adapts position based on device orientation.
//  Portrait: Bottom of screen
//  Landscape: Right edge (like native iOS Camera app)
//

import SwiftUI

/// Adaptive toolbar that positions record button centered and thumbnail button offset
struct AdaptiveToolbar: View {

    let isLandscape: Bool
    let thumbnail: UIImage?
    let isRecording: Bool
    let onThumbnailTap: () -> Void
    let onRecordTap: () -> Void

    var body: some View {
        if isLandscape {
            // Landscape: controls on right edge
            // Record button centered vertically, thumbnail at top
            HStack {
                Spacer()
                ZStack {
                    // Record button - centered
                    RecordButton(isRecording: isRecording, action: onRecordTap)

                    // Thumbnail button - top aligned
                    VStack {
                        ThumbnailButton(thumbnail: thumbnail, action: onThumbnailTap)
                        Spacer()
                    }
                }
                .padding(.trailing, 30)
                .padding(.vertical, 40)
            }
        } else {
            // Portrait: controls at bottom
            // Record button centered horizontally, thumbnail on left
            VStack {
                Spacer()
                ZStack {
                    // Record button - centered
                    RecordButton(isRecording: isRecording, action: onRecordTap)

                    // Thumbnail button - left aligned
                    HStack {
                        ThumbnailButton(thumbnail: thumbnail, action: onThumbnailTap)
                        Spacer()
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview("Portrait") {
    ZStack {
        Color.black.ignoresSafeArea()
        AdaptiveToolbar(
            isLandscape: false,
            thumbnail: nil,
            isRecording: false,
            onThumbnailTap: {},
            onRecordTap: {}
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
            onThumbnailTap: {},
            onRecordTap: {}
        )
    }
}
