import CoreGraphics

/// 3x3 grid zones for exposure metering point selection
/// Used to tell the camera which area of the frame to use for auto-exposure calculations
enum MeteringZone: Int, CaseIterable, Identifiable, Equatable {
    case topLeft = 1
    case topCenter = 2
    case topRight = 3
    case middleLeft = 4
    case center = 5
    case middleRight = 6
    case bottomLeft = 7
    case bottomCenter = 8
    case bottomRight = 9

    var id: Int { rawValue }

    /// Grid position (0-2, 0-2)
    var column: Int { (rawValue - 1) % 3 }
    var row: Int { (rawValue - 1) / 3 }

    /// Convert to AVFoundation coordinate system
    /// (0,0) = top-left, (1,1) = bottom-right in landscape-right orientation
    /// Note: Uses 0.51 instead of 0.5 to avoid known iOS bug
    var point: CGPoint {
        // Map zones to points at 1/6, 1/2, 5/6 of each axis
        let positions: [CGFloat] = [0.167, 0.51, 0.833]  // 0.51 instead of 0.5 for center

        return CGPoint(
            x: positions[column],
            y: positions[row]
        )
    }

    /// Human-readable label for display
    var label: String {
        switch self {
        case .topLeft: return "Top Left"
        case .topCenter: return "Top"
        case .topRight: return "Top Right"
        case .middleLeft: return "Left"
        case .center: return "Center"
        case .middleRight: return "Right"
        case .bottomLeft: return "Bottom Left"
        case .bottomCenter: return "Bottom"
        case .bottomRight: return "Bottom Right"
        }
    }

    /// Short label for compact display
    var shortLabel: String {
        switch self {
        case .topLeft: return "TL"
        case .topCenter: return "T"
        case .topRight: return "TR"
        case .middleLeft: return "L"
        case .center: return "C"
        case .middleRight: return "R"
        case .bottomLeft: return "BL"
        case .bottomCenter: return "B"
        case .bottomRight: return "BR"
        }
    }

    /// String value for JSON serialization
    var stringValue: String {
        switch self {
        case .topLeft: return "topLeft"
        case .topCenter: return "topCenter"
        case .topRight: return "topRight"
        case .middleLeft: return "middleLeft"
        case .center: return "center"
        case .middleRight: return "middleRight"
        case .bottomLeft: return "bottomLeft"
        case .bottomCenter: return "bottomCenter"
        case .bottomRight: return "bottomRight"
        }
    }

    /// Create from string value (for JSON decoding)
    static func from(string: String) -> MeteringZone? {
        switch string {
        case "topLeft": return .topLeft
        case "topCenter": return .topCenter
        case "topRight": return .topRight
        case "middleLeft": return .middleLeft
        case "center": return .center
        case "middleRight": return .middleRight
        case "bottomLeft": return .bottomLeft
        case "bottomCenter": return .bottomCenter
        case "bottomRight": return .bottomRight
        default: return nil
        }
    }
}
