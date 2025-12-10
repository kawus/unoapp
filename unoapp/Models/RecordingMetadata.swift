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

    // MARK: - Convenience Initializer

    init(preset: CameraPreset, settings: CameraSettings, lens: CameraLens? = nil, recordedAt: Date = Date()) {
        self.preset = preset.rawValue
        self.exposureBias = settings.exposureBias
        self.meteringZone = settings.meteringZone.stringValue
        self.iso = settings.iso
        self.whiteBalance = settings.whiteBalance
        self.recordedAt = recordedAt
        self.lens = lens?.rawValue
    }

    // MARK: - Display Helpers

    /// Lens label for display: "0.5x" or "1x"
    var lensLabel: String? {
        guard let lens = lens else { return nil }
        return lens == "ultraWide" ? "0.5x" : "1x"
    }

    /// Summary line for list view: "0.5x • Floodlight • -1.0 EV"
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

        if let lensLabel = lensLabel {
            return "\(lensLabel) • \(presetName) • \(evText)"
        }
        return "\(presetName) • \(evText)"
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

        lines.append(contentsOf: [
            ("Preset", preset.capitalized),
            ("Exposure", exposureBias == 0 ? "0 EV" : String(format: "%+.1f EV", exposureBias)),
            ("Metering", zoneLabel),
            ("ISO", "\(Int(iso))"),
            ("White Balance", "\(whiteBalance)K")
        ])

        return lines
    }
}
