//
//  DebugOverlayView.swift
//  unoapp
//
//  On-screen debug overlay showing real-time camera configuration.
//  Toggle visibility with triple-tap on camera preview.
//  Designed to be non-intrusive while providing comprehensive info for field testing.
//

import SwiftUI

/// On-screen debug overlay showing real-time camera configuration
struct DebugOverlayView: View {
    let info: CameraDebugInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)
                Text("Debug")
                    .font(.caption.bold())
            }

            Divider()
                .background(.white.opacity(0.3))

            // FOV - Most Important (highlighted)
            DebugRow(label: "FOV",
                    value: String(format: "%.1f°", info.videoFieldOfView),
                    highlight: true)

            // Resolution & Format
            DebugRow(label: "Resolution", value: info.resolution)
            DebugRow(label: "Aspect", value: info.aspectRatio)
            DebugRow(label: "FPS", value: String(format: "%.0f", info.frameRate))

            Divider().background(.white.opacity(0.3))

            // Camera Configuration
            DebugRow(label: "Lens", value: info.lens)
            DebugRow(label: "Zoom", value: String(format: "%.2fx", info.videoZoomFactor))

            Divider().background(.white.opacity(0.3))

            // FOV-Critical Settings (green = good for FOV)
            DebugRow(label: "GDC",
                    value: gdcStatusText,
                    highlight: !info.gdcEnabled && info.gdcSupported)
            DebugRow(label: "Stab",
                    value: info.stabilizationMode,
                    highlight: info.stabilizationMode == "off")
            DebugRow(label: "Preset", value: info.sessionPreset)
            DebugRow(label: "Max FOV",
                    value: info.maxFOVEnabled ? "ON" : "OFF",
                    highlight: info.maxFOVEnabled)
        }
        .font(.system(size: 11, design: .monospaced))
        .foregroundStyle(.white.opacity(0.9))
        .padding(12)
        .frame(width: 160)
        .background(.ultraThinMaterial.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }

    /// GDC status with context
    private var gdcStatusText: String {
        if !info.gdcSupported {
            return "N/A"
        }
        return info.gdcEnabled ? "ON (crops)" : "OFF"
    }
}

/// Single row in debug overlay
struct DebugRow: View {
    let label: String
    let value: String
    var highlight: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            Text(value)
                .foregroundStyle(highlight ? .green : .white)
                .fontWeight(highlight ? .semibold : .regular)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            HStack {
                Spacer()
                DebugOverlayView(info: CameraDebugInfo(
                    resolution: "3840x2160",
                    videoFieldOfView: 77.3,
                    frameRate: 30,
                    aspectRatio: "16:9",
                    gdcEnabled: false,
                    gdcSupported: true,
                    stabilizationMode: "off",
                    sessionPreset: "inputPriority",
                    lens: "Wide (1x)",
                    videoZoomFactor: 1.0,
                    maxFOVEnabled: true
                ))
                .padding()
            }
            Spacer()
        }
    }
}
