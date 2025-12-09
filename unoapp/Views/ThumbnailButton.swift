//
//  ThumbnailButton.swift
//  unoapp
//
//  Small thumbnail button showing most recent recording.
//  Positioned in corner of camera view (like native Camera app).
//

import SwiftUI

/// Small thumbnail button showing most recent recording
/// Tapping opens the recordings list
/// Includes press feedback animation
struct ThumbnailButton: View {

    let thumbnail: UIImage?
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Group {
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.white.opacity(0.5), lineWidth: 1)
                        }
                } else {
                    // Placeholder when no recordings exist
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: "photo.stack")
                                .foregroundStyle(.white.opacity(0.7))
                        }
                }
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .animation(.easeOut(duration: 0.1), value: isPressed)
    }
}

// MARK: - Preview

#Preview("With Thumbnail") {
    ZStack {
        Color.black.ignoresSafeArea()
        ThumbnailButton(thumbnail: UIImage(systemName: "video.fill")) {
            print("Tapped")
        }
    }
}

#Preview("No Thumbnail") {
    ZStack {
        Color.black.ignoresSafeArea()
        ThumbnailButton(thumbnail: nil) {
            print("Tapped")
        }
    }
}
