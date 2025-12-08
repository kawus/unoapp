import Foundation

/// Camera exposure and white balance settings
struct CameraSettings: Equatable {
    var iso: Float              // 100-1600
    var exposureBias: Float     // -2.0 to +2.0 EV
    var whiteBalance: Int       // 3000K-7000K (Kelvin)
    var meteringZone: MeteringZone  // Which zone to use for auto-exposure

    // MARK: - Preset Defaults

    /// Cloudy daylight: higher ISO, warmer tones
    static let cloudy = CameraSettings(
        iso: 400,
        exposureBias: 0.5,
        whiteBalance: 6500,
        meteringZone: .center
    )

    /// Bright sunny conditions: low ISO, neutral white balance
    static let sunny = CameraSettings(
        iso: 100,
        exposureBias: -0.5,
        whiteBalance: 5500,
        meteringZone: .center
    )

    /// Stadium floodlights: compensate for sodium lamp orange cast
    /// Negative exposure bias based on real-world testing
    /// Meters on bottom-center to avoid bright lights at top of frame
    static let floodlight = CameraSettings(
        iso: 800,
        exposureBias: -1.0,
        whiteBalance: 4000,
        meteringZone: .bottomCenter
    )

    /// Default starting point for manual adjustments
    static let defaultManual = CameraSettings(
        iso: 400,
        exposureBias: 0,
        whiteBalance: 5500,
        meteringZone: .center
    )

    // MARK: - Value Ranges

    static let isoRange: ClosedRange<Float> = 100...1600
    static let isoStep: Float = 100

    static let exposureRange: ClosedRange<Float> = -2.0...2.0
    static let exposureStep: Float = 0.5

    static let whiteBalanceRange: ClosedRange<Int> = 3000...7000
    static let whiteBalanceStep: Int = 500

    // MARK: - Formatting

    var isoDisplay: String {
        "ISO \(Int(iso))"
    }

    var exposureDisplay: String {
        if exposureBias == 0 {
            return "EV 0"
        } else if exposureBias > 0 {
            return "EV +\(String(format: "%.1f", exposureBias))"
        } else {
            return "EV \(String(format: "%.1f", exposureBias))"
        }
    }

    var whiteBalanceDisplay: String {
        "\(whiteBalance)K"
    }

    var meteringZoneDisplay: String {
        meteringZone.label
    }

    // MARK: - Adjustment Methods

    mutating func adjustISO(by direction: Int) {
        let newValue = iso + (Float(direction) * Self.isoStep)
        iso = min(max(newValue, Self.isoRange.lowerBound), Self.isoRange.upperBound)
    }

    mutating func adjustExposure(by direction: Int) {
        let newValue = exposureBias + (Float(direction) * Self.exposureStep)
        exposureBias = min(max(newValue, Self.exposureRange.lowerBound), Self.exposureRange.upperBound)
    }

    mutating func adjustWhiteBalance(by direction: Int) {
        let newValue = whiteBalance + (direction * Self.whiteBalanceStep)
        whiteBalance = min(max(newValue, Self.whiteBalanceRange.lowerBound), Self.whiteBalanceRange.upperBound)
    }
}
