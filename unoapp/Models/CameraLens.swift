import AVFoundation

/// Camera lens options for switching between ultrawide and wide cameras
enum CameraLens: String, CaseIterable, Identifiable {
    case ultraWide  // 0.5x - builtInUltraWideCamera
    case wide       // 1x - builtInWideAngleCamera

    var id: String { rawValue }

    /// AVFoundation device type for this lens
    var deviceType: AVCaptureDevice.DeviceType {
        switch self {
        case .ultraWide: return .builtInUltraWideCamera
        case .wide: return .builtInWideAngleCamera
        }
    }

    /// Display label (zoom multiplier)
    var label: String {
        switch self {
        case .ultraWide: return "0.5"
        case .wide: return "1"
        }
    }

    /// Accessibility label
    var accessibilityLabel: String {
        switch self {
        case .ultraWide: return "Ultra wide camera, 0.5x zoom"
        case .wide: return "Wide camera, 1x zoom"
        }
    }
}
