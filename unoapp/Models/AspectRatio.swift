//
//  AspectRatio.swift
//  unoapp
//
//  Aspect ratio options for video capture.
//  4:3 captures more of the circular fisheye projection than 16:9.
//

import Foundation

/// Video aspect ratio options
/// 4:3 is closer to a circle than 16:9, so it captures more of the fisheye lens projection
enum AspectRatio: String, CaseIterable, Codable {
    case sixteenByNine = "16:9"   // Standard widescreen (default)
    case fourByThree = "4:3"      // Captures more vertical FOV

    /// Display label for UI
    var label: String {
        rawValue
    }

    /// Numeric ratio (width / height)
    var ratio: CGFloat {
        switch self {
        case .sixteenByNine: return 16.0 / 9.0
        case .fourByThree: return 4.0 / 3.0
        }
    }

    /// Returns true if this is a "tall" format (more vertical coverage)
    var isTall: Bool {
        self == .fourByThree
    }

    /// Accessibility label
    var accessibilityLabel: String {
        switch self {
        case .sixteenByNine: return "16 by 9 widescreen aspect ratio"
        case .fourByThree: return "4 by 3 aspect ratio, captures more vertical field of view"
        }
    }
}
