import Foundation

/// Lighting presets for different filming conditions
enum CameraPreset: String, CaseIterable, Identifiable {
    case cloudy
    case sunny
    case floodlight
    case manual

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .cloudy: return "cloud.fill"
        case .sunny: return "sun.max.fill"
        case .floodlight: return "light.overhead.right.fill"
        case .manual: return "slider.horizontal.3"
        }
    }

    var label: String {
        switch self {
        case .cloudy: return "Cloudy"
        case .sunny: return "Sunny"
        case .floodlight: return "Flood"
        case .manual: return "Manual"
        }
    }
}
