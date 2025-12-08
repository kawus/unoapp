//
//  CameraPreviewView.swift
//  unoapp
//
//  Created by Kawus Nouri on 05/12/2025.
//
//  UIViewRepresentable wrapper for AVCaptureVideoPreviewLayer.
//  Displays the live camera feed in SwiftUI.
//

import SwiftUI
import AVFoundation

/// SwiftUI view that displays the live camera preview
/// Uses UIViewRepresentable to bridge AVCaptureVideoPreviewLayer to SwiftUI
struct CameraPreviewView: UIViewRepresentable {

    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.session = session
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        // Session is set once during creation, no updates needed
    }
}

/// UIView subclass that hosts the AVCaptureVideoPreviewLayer
/// Handles proper layer sizing, video gravity, and rotation
final class CameraPreviewUIView: UIView {

    // The preview layer that displays the camera feed
    private var previewLayer: AVCaptureVideoPreviewLayer?

    var session: AVCaptureSession? {
        didSet {
            setupPreviewLayer()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black

        // Listen for orientation changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOrientationChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupPreviewLayer() {
        // Remove existing preview layer if any
        previewLayer?.removeFromSuperlayer()

        guard let session = session else { return }

        // Create new preview layer
        let layer = AVCaptureVideoPreviewLayer(session: session)

        // Fill the entire view while maintaining aspect ratio
        // This ensures the full fisheye distortion is visible
        layer.videoGravity = .resizeAspectFill

        layer.frame = bounds
        self.layer.addSublayer(layer)
        previewLayer = layer

        // Set initial orientation
        updatePreviewOrientation()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Update preview layer frame when view size changes
        previewLayer?.frame = bounds
    }

    @objc private func handleOrientationChange() {
        updatePreviewOrientation()
    }

    /// Update preview layer rotation to match device orientation
    private func updatePreviewOrientation() {
        guard let connection = previewLayer?.connection,
              connection.isVideoRotationAngleSupported(0) else { return }

        let orientation = UIDevice.current.orientation

        // Map device orientation to video rotation angle
        // These values ensure the preview is right-side-up for each orientation
        let rotationAngle: CGFloat
        switch orientation {
        case .portrait:
            rotationAngle = 90
        case .portraitUpsideDown:
            rotationAngle = 270
        case .landscapeLeft:
            // Home button on right
            rotationAngle = 0
        case .landscapeRight:
            // Home button on left
            rotationAngle = 180
        default:
            // For .faceUp, .faceDown, .unknown - keep current
            return
        }

        if connection.isVideoRotationAngleSupported(rotationAngle) {
            connection.videoRotationAngle = rotationAngle
        }
    }
}

// MARK: - Preview

#Preview {
    // Preview with a mock session (won't show actual camera in preview)
    CameraPreviewView(session: AVCaptureSession())
        .ignoresSafeArea()
}
