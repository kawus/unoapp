//
//  CameraViewModel.swift
//  unoapp
//
//  Created by Kawus Nouri on 05/12/2025.
//
//  Manages camera state, permissions, and recording lifecycle.
//  Acts as the bridge between SwiftUI views and CameraManager.
//

import SwiftUI
import AVFoundation
import Combine

/// ViewModel for camera operations and state management
@MainActor
final class CameraViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Current camera permission status
    @Published var permissionStatus: AVAuthorizationStatus = .notDetermined

    /// Whether the camera is currently recording
    @Published var isRecording: Bool = false

    /// Duration of the current recording in seconds
    @Published var recordingDuration: TimeInterval = 0

    /// Most recent error message to display to user
    @Published var errorMessage: String?

    /// Shows brief confirmation after recording saved
    @Published var showRecordingSaved: Bool = false

    // MARK: - Camera Manager

    let cameraManager = CameraManager()

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        // Check initial permission status
        permissionStatus = AVCaptureDevice.authorizationStatus(for: .video)

        // Subscribe to CameraManager state changes
        setupBindings()

        // Setup recording callback
        cameraManager.onRecordingFinished = { [weak self] url in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.handleRecordingFinished(url: url)
            }
        }
    }

    // MARK: - Setup

    private func setupBindings() {
        // Forward isRecording state
        cameraManager.$isRecording
            .receive(on: DispatchQueue.main)
            .assign(to: &$isRecording)

        // Forward recording duration
        cameraManager.$recordingDuration
            .receive(on: DispatchQueue.main)
            .assign(to: &$recordingDuration)

        // Forward errors
        cameraManager.$error
            .receive(on: DispatchQueue.main)
            .compactMap { $0?.errorDescription }
            .assign(to: &$errorMessage)
    }

    // MARK: - Permission Handling

    /// Request camera permission from the user
    func requestPermission() {
        Task {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            permissionStatus = granted ? .authorized : .denied

            if granted {
                setupCamera()
            }
        }
    }

    // MARK: - Camera Setup

    /// Setup and start the camera session
    /// Call this after permission is granted
    func setupCamera() {
        cameraManager.setupSession()
        cameraManager.startSession()
    }

    // MARK: - Recording

    /// Toggle recording state - start if stopped, stop if recording
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    /// Start a new recording
    func startRecording() {
        errorMessage = nil
        cameraManager.startRecording()
    }

    /// Stop the current recording
    func stopRecording() {
        cameraManager.stopRecording()
    }

    // MARK: - Recording Completion

    private func handleRecordingFinished(url: URL) {
        // Show brief confirmation to user
        showRecordingSaved = true

        // Hide after 2 seconds
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            showRecordingSaved = false
        }

        // Log for debugging
        print("Recording saved: \(url.lastPathComponent)")
    }

    // MARK: - Utility

    /// Format recording duration as MM:SS
    var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Cleanup

    func stopCamera() {
        cameraManager.stopSession()
    }
}
