//
//  OrientationManager.swift
//  unoapp
//
//  Tracks device orientation and publishes landscape state.
//  SwiftUI's sizeClass doesn't reliably distinguish portrait/landscape on iPhone.
//

import SwiftUI
import Combine

/// Tracks device orientation and publishes whether device is in landscape mode
/// Why needed: SwiftUI's @Environment(\.horizontalSizeClass) returns .compact
/// for both portrait and landscape on iPhone, so we need manual tracking.
@Observable
final class OrientationManager {

    /// True when device is in landscape orientation (left or right)
    var isLandscape: Bool = false

    private var cancellable: AnyCancellable?

    init() {
        // Get initial orientation state
        updateOrientation()

        // Listen for orientation changes
        cancellable = NotificationCenter.default
            .publisher(for: UIDevice.orientationDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateOrientation()
            }

        // Enable orientation change notifications
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    }

    deinit {
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }

    /// Updates isLandscape based on current device orientation
    private func updateOrientation() {
        let orientation = UIDevice.current.orientation

        // Only update for valid interface orientations
        // Ignore .faceUp, .faceDown, and .unknown
        if orientation.isValidInterfaceOrientation {
            isLandscape = orientation.isLandscape
        }
    }
}
