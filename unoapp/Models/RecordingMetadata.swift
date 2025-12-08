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

    // MARK: - Convenience Initializer

    init(preset: CameraPreset, settings: CameraSettings, recordedAt: Date = Date()) {
        self.preset = preset.rawValue
        self.exposureBias = settings.exposureBias
        self.meteringZone = settings.meteringZone.stringValue
        self.iso = settings.iso
        self.whiteBalance = settings.whiteBalance
        self.recordedAt = recordedAt
    }

    // MARK: - Display Helpers

    /// Summary line for list view: "Floodlight • -1.0 EV"
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
        return "\(presetName) • \(evText)"
    }

    /// Full details for playback view
    var detailLines: [(label: String, value: String)] {
        let zoneLabel = meteringZone
            .replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
            .capitalized

        return [
            ("Preset", preset.capitalized),
            ("Exposure", exposureBias == 0 ? "0 EV" : String(format: "%+.1f EV", exposureBias)),
            ("Metering", zoneLabel),
            ("ISO", "\(Int(iso))"),
            ("White Balance", "\(whiteBalance)K")
        ]
    }
}
