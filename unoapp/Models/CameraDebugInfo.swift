//
//  CameraDebugInfo.swift
//  unoapp
//
//  Real-time camera diagnostic information for field testing.
//  Displayed in on-screen overlay (toggle with triple-tap).
//

import Foundation

/// Real-time camera diagnostic information for debug overlay
struct CameraDebugInfo: Equatable {
    // Format Information
    let resolution: String           // "3840x2160"
    let videoFieldOfView: Float      // Hardware FOV in degrees
    let frameRate: Float             // Current frame rate
    let aspectRatio: String          // "16:9" or "4:3"

    // Configuration Status
    let gdcEnabled: Bool             // Geometric Distortion Correction
    let gdcSupported: Bool           // Whether device supports GDC
    let stabilizationMode: String    // "off", "standard", etc.
    let sessionPreset: String        // "inputPriority", "high", etc.

    // Lens Information
    let lens: String                 // "Wide (1x)" or "Ultra Wide (0.5x)"
    let videoZoomFactor: Float       // Current zoom factor

    // Max FOV Mode Status
    let maxFOVEnabled: Bool
}
