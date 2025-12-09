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

    /// URL of the most recently saved recording (for thumbnail generation)
    @Published var lastRecordingURL: URL?

    /// Currently selected lighting preset
    @Published var selectedPreset: CameraPreset = .sunny

    /// Manual camera settings (used when preset is .manual)
    @Published var manualSettings: CameraSettings = .defaultManual

    /// Whether manual controls panel is visible (can be collapsed while staying in manual mode)
    @Published var showManualControls: Bool = false

    /// Whether the metering grid overlay is visible
    @Published var showMeteringGrid: Bool = false

    /// Currently selected metering zone (tracks user's choice, persists across preset changes until explicitly reset)
    @Published var selectedMeteringZone: MeteringZone = .center

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

    /// Start a new recording with current settings
    func startRecording() {
        errorMessage = nil

        // Get base settings from preset
        var settings: CameraSettings
        switch selectedPreset {
        case .cloudy:
            settings = .cloudy
        case .sunny:
            settings = .sunny
        case .floodlight:
            settings = .floodlight
        case .manual:
            settings = manualSettings
        }

        // Override metering zone with user's actual selection
        settings.meteringZone = selectedMeteringZone

        cameraManager.startRecording(preset: selectedPreset, settings: settings)
    }

    /// Stop the current recording
    func stopRecording() {
        cameraManager.stopRecording()
    }

    // MARK: - Recording Completion

    private func handleRecordingFinished(url: URL) {
        // Store URL for thumbnail generation
        lastRecordingURL = url

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

    // MARK: - Preset Selection

    /// Select a lighting preset and apply its settings
    func selectPreset(_ preset: CameraPreset) {
        selectedPreset = preset
        // Auto-show controls when switching to manual
        if preset == .manual {
            showManualControls = true
        }
        // Reset metering zone to preset's default when switching presets
        let presetSettings: CameraSettings
        switch preset {
        case .cloudy: presetSettings = .cloudy
        case .sunny: presetSettings = .sunny
        case .floodlight: presetSettings = .floodlight
        case .manual: presetSettings = manualSettings
        }
        selectedMeteringZone = presetSettings.meteringZone
        applyCurrentSettings()
    }

    /// Dismiss manual controls panel (stays in manual mode)
    func dismissManualControls() {
        showManualControls = false
    }

    /// Apply manual settings (called when steppers change in manual mode)
    func applyManualSettings(_ settings: CameraSettings) {
        manualSettings = settings
        if selectedPreset == .manual {
            cameraManager.applySettings(settings)
        }
    }

    /// Apply camera settings based on current preset
    private func applyCurrentSettings() {
        let settings: CameraSettings
        switch selectedPreset {
        case .cloudy:
            settings = .cloudy
        case .sunny:
            settings = .sunny
        case .floodlight:
            settings = .floodlight
        case .manual:
            settings = manualSettings
        }
        cameraManager.applySettings(settings)
    }

    // MARK: - Metering Grid

    /// Toggle the metering grid overlay visibility
    func toggleMeteringGrid() {
        showMeteringGrid.toggle()
    }

    /// Select a metering zone for exposure calculations
    /// Updates current settings and applies immediately
    func selectMeteringZone(_ zone: MeteringZone) {
        // Track the user's zone selection
        selectedMeteringZone = zone

        // Also update manual settings if in manual mode (keeps them in sync)
        if selectedPreset == .manual {
            manualSettings.meteringZone = zone
        }

        // Apply the zone immediately to camera
        cameraManager.applyMeteringZone(zone)
    }

    /// Current metering zone (returns user's actual selection)
    var currentMeteringZone: MeteringZone {
        selectedMeteringZone
    }

    // MARK: - Cleanup

    func stopCamera() {
        cameraManager.stopSession()
    }
}
