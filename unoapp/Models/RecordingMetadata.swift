//
//  RecordingMetadata.swift
//  unoapp
//
//  Camera settings captured when a recording was made.
//  Used to review and recreate successful shots during field testing.
//

import Foundation

/// Settings captured when a recording was made
struct RecordingMetadata: Codable, Equatable {
    let preset: String              // "cloudy", "sunny", "floodlight", "manual"
    let exposureBias: Float         // -2.0 to +2.0 EV
    let meteringZone: String        // "center", "bottomCenter", etc.
    let iso: Float                  // For display (stored but not all applied yet)
    let whiteBalance: Int           // For display (stored but not all applied yet)
    let recordedAt: Date            // Timestamp for verification
    let lens: String?               // "ultraWide" or "wide" (optional for backward compatibility)
    let maxFOV: Bool?               // Whether Max FOV mode was enabled (optional for backward compatibility)
    let aspectRatio: String?        // "16:9" or "4:3" (optional for backward compatibility)
    let audioEnabled: Bool?         // Whether audio was recorded (optional for backward compatibility)
    let audioInputName: String?     // "Built-In Microphone", "USB Audio", etc.

    // MARK: - Convenience Initializer

    init(preset: CameraPreset, settings: CameraSettings, lens: CameraLens? = nil, maxFOV: Bool = false, aspectRatio: AspectRatio = .sixteenByNine, audioEnabled: Bool = false, audioInputName: String? = nil, recordedAt: Date = Date()) {
        self.preset = preset.rawValue
        self.exposureBias = settings.exposureBias
        self.meteringZone = settings.meteringZone.stringValue
        self.iso = settings.iso
        self.whiteBalance = settings.whiteBalance
        self.recordedAt = recordedAt
        self.lens = lens?.rawValue
        self.maxFOV = maxFOV
        self.aspectRatio = aspectRatio.rawValue
        self.audioEnabled = audioEnabled
        self.audioInputName = audioInputName
    }

    // MARK: - Display Helpers

    /// Lens label for display: "0.5x" or "1x"
    var lensLabel: String? {
        guard let lens = lens else { return nil }
        return lens == "ultraWide" ? "0.5x" : "1x"
    }

    /// Summary line for list view: "0.5x • Floodlight • -1.0 EV • MaxFOV"
    var summaryText: String {
        let presetName = preset.capitalized
        let evText: String
        if exposureBias == 0 {
            evText = "EV 0"
        } else if exposureBias > 0 {
            evText = "EV +\(String(format: "%.1f", exposureBias))"
        } else {
            evText = "EV \(String(format: "%.1f", exposureBias))"
        }

        var parts: [String] = []
        if let lensLabel = lensLabel {
            parts.append(lensLabel)
        }
        // Show aspect ratio if not default 16:9
        if let ratio = aspectRatio, ratio != "16:9" {
            parts.append(ratio)
        }
        parts.append(presetName)
        parts.append(evText)
        if maxFOV == true {
            parts.append("MaxFOV")
        }
        if audioEnabled == true {
            parts.append("Audio")
        }
        return parts.joined(separator: " • ")
    }

    /// Full details for playback view
    var detailLines: [(label: String, value: String)] {
        let zoneLabel = meteringZone
            .replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
            .capitalized

        var lines: [(label: String, value: String)] = []

        // Add lens if available
        if let lensLabel = lensLabel {
            lines.append(("Lens", lensLabel))
        }

        // Add Max FOV mode if enabled
        if maxFOV == true {
            lines.append(("Max FOV", "On"))
        }

        // Add aspect ratio if available
        if let ratio = aspectRatio {
            lines.append(("Aspect Ratio", ratio))
        }

        lines.append(contentsOf: [
            ("Preset", preset.capitalized),
            ("Exposure", exposureBias == 0 ? "0 EV" : String(format: "%+.1f EV", exposureBias)),
            ("Metering", zoneLabel),
            ("ISO", "\(Int(iso))"),
            ("White Balance", "\(whiteBalance)K")
        ])

        // Add audio info if available
        if let audioEnabled = audioEnabled {
            let audioValue = audioEnabled ? (audioInputName ?? "On") : "Off"
            lines.append(("Audio", audioValue))
        }

        return lines
    }
}
