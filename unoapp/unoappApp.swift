//
//  unoappApp.swift
//  unoapp
//
//  Created by Kawus Nouri on 05/12/2025.
//
//  Proof-of-concept app to validate single iPhone + Moment fisheye lens
//  capture of a full football pitch (180° FOV).
//

import AVFoundation
import SwiftUI

@main
struct UnoappApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

/// Root view that handles camera permission state and navigation
struct ContentView: View {
    @StateObject private var cameraViewModel = CameraViewModel()

    var body: some View {
        Group {
            switch cameraViewModel.permissionStatus {
            case .authorized:
                ViewfinderView(viewModel: cameraViewModel)
            case .denied, .restricted:
                PermissionView()
            case .notDetermined:
                // Show loading while we request permission
                ProgressView("Requesting camera access...")
                    .onAppear {
                        cameraViewModel.requestPermission()
                    }
            @unknown default:
                PermissionView()
            }
        }
        .preferredColorScheme(.dark) // Camera apps work best in dark mode
    }
}
