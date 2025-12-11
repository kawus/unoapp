//
//  CameraManager.swift
//  unoapp
//
//  Created by Kawus Nouri on 05/12/2025.
//
//  Handles AVFoundation camera setup and video recording.
//  Configured for ultrawide lens with stabilization disabled for maximum FOV.
//

import AVFoundation
import Combine
import UIKit

/// Manages the camera capture session and video recording
/// Key features:
/// - Hardcoded to ultrawide camera for maximum FOV with Moment fisheye
/// - Stabilization disabled to prevent FOV cropping
/// - 4K 30fps output for quality/size balance
final class CameraManager: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var error: CameraError?

    // MARK: - Camera Session

    let captureSession = AVCaptureSession()
    private var videoOutput: AVCaptureMovieFileOutput?
    private var videoDevice: AVCaptureDevice?
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?

    // MARK: - Recording Storage

    private var currentRecordingURL: URL?
    private var currentRecordingMetadata: (preset: CameraPreset, settings: CameraSettings, lens: CameraLens, maxFOV: Bool)?
    var onRecordingFinished: ((URL) -> Void)?

    /// Currently active camera lens
    private(set) var currentLens: CameraLens = .ultraWide

    /// Whether Max FOV mode is enabled (disables distortion correction, selects max FOV format)
    private(set) var maxFOVEnabled: Bool = false

    // MARK: - Initialization

    override init() {
        super.init()
    }

    // MARK: - Setup

    /// Configure the capture session with ultrawide camera and 4K 30fps
    /// Call this after camera permission is granted
    func setupSession() {
        captureSession.beginConfiguration()

        // Set session preset for high quality video
        captureSession.sessionPreset = .high

        // Step 1: Get the ultrawide camera (hardcoded per pitch requirements)
        guard let ultraWideCamera = AVCaptureDevice.default(
            .builtInUltraWideCamera,
            for: .video,
            position: .back
        ) else {
            error = .noUltraWideCamera
            captureSession.commitConfiguration()
            return
        }

        videoDevice = ultraWideCamera

        // Log all available formats for debugging FOV options
        logAvailableFormats(device: ultraWideCamera)

        // Step 2: Configure for 4K 30fps
        configure4K30fps(device: ultraWideCamera)

        // Step 3: Add video input
        do {
            let videoInput = try AVCaptureDeviceInput(device: ultraWideCamera)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                error = .cannotAddInput
                captureSession.commitConfiguration()
                return
            }
        } catch {
            self.error = .inputCreationFailed(error.localizedDescription)
            captureSession.commitConfiguration()
            return
        }

        // Step 4: Add movie file output for recording
        let movieOutput = AVCaptureMovieFileOutput()
        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)
            videoOutput = movieOutput

            // CRITICAL: Disable video stabilization for maximum FOV
            // This is the whole point of this PoC - stabilization crops the image
            if let connection = movieOutput.connection(with: .video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .off
                }
            }
        } else {
            error = .cannotAddOutput
            captureSession.commitConfiguration()
            return
        }

        captureSession.commitConfiguration()
    }

    /// Log all available formats for a device (for debugging FOV options)
    private func logAvailableFormats(device: AVCaptureDevice) {
        print("=== Available formats for \(device.localizedName) ===")
        print("[Info] GDC Supported: \(device.isGeometricDistortionCorrectionSupported)")

        // Group by resolution for cleaner output
        var formatsByResolution: [String: [(format: AVCaptureDevice.Format, fov: Float)]] = [:]

        for format in device.formats {
            let dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            let key = "\(dims.width)x\(dims.height)"
            let fov = format.videoFieldOfView

            if formatsByResolution[key] == nil {
                formatsByResolution[key] = []
            }
            formatsByResolution[key]?.append((format, fov))
        }

        // Print unique FOV values per resolution
        for (resolution, formats) in formatsByResolution.sorted(by: { $0.key > $1.key }) {
            let uniqueFOVs = Set(formats.map { $0.fov }).sorted(by: >)
            let fovString = uniqueFOVs.map { String(format: "%.1f°", $0) }.joined(separator: ", ")
            print("  \(resolution): FOV \(fovString)")
        }
        print("=== End formats ===")
    }

    /// Configure the camera device for 4K 30fps output
    private func configure4K30fps(device: AVCaptureDevice) {
        // Find the best 4K 30fps format
        let targetWidth: Int32 = 3840
        let targetHeight: Int32 = 2160
        let targetFrameRate: Float64 = 30.0

        // Look for a format that supports 4K at 30fps
        let supportedFormats = device.formats.filter { format in
            let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            let supports30fps = format.videoSupportedFrameRateRanges.contains { range in
                range.maxFrameRate >= targetFrameRate
            }
            return dimensions.width >= targetWidth &&
                   dimensions.height >= targetHeight &&
                   supports30fps
        }

        // Use the first matching format, or fall back to device default
        guard let bestFormat = supportedFormats.first else {
            // Device doesn't support 4K - use best available
            return
        }

        let dimensions = CMVideoFormatDescriptionGetDimensions(bestFormat.formatDescription)
        print("[Standard] Format: \(dimensions.width)x\(dimensions.height), FOV: \(bestFormat.videoFieldOfView)°")

        do {
            try device.lockForConfiguration()
            device.activeFormat = bestFormat

            // Set frame rate to 30fps
            let frameRateRange = bestFormat.videoSupportedFrameRateRanges.first { range in
                range.maxFrameRate >= targetFrameRate
            }

            if frameRateRange != nil {
                let duration = CMTime(value: 1, timescale: CMTimeScale(targetFrameRate))
                device.activeVideoMinFrameDuration = duration
                device.activeVideoMaxFrameDuration = duration
            }

            device.unlockForConfiguration()
        } catch {
            // If we can't configure, use defaults - not a critical error
            print("Could not configure 4K 30fps: \(error.localizedDescription)")
        }
    }

    // MARK: - Camera Settings

    /// Apply camera settings (exposure bias, ISO, white balance)
    /// Note: Currently implements exposure bias only - the simplest and most effective control.
    /// Full ISO/WB control can be added later if exposure bias alone isn't sufficient.
    func applySettings(_ settings: CameraSettings) {
        guard let device = videoDevice else { return }

        do {
            try device.lockForConfiguration()

            // Apply exposure bias (works with auto-exposure)
            // This is the main control - similar to native camera exposure dial
            let clampedBias = max(device.minExposureTargetBias,
                                  min(settings.exposureBias, device.maxExposureTargetBias))
            device.setExposureTargetBias(clampedBias, completionHandler: nil)

            device.unlockForConfiguration()
        } catch {
            print("Could not apply camera settings: \(error.localizedDescription)")
        }

        // Also apply metering zone
        applyMeteringZone(settings.meteringZone)
    }

    /// Set the exposure metering zone
    /// Tells the camera which area of the frame to use for auto-exposure calculations
    func applyMeteringZone(_ zone: MeteringZone) {
        guard let device = videoDevice else { return }

        // Check if device supports point of interest for exposure
        guard device.isExposurePointOfInterestSupported else {
            print("Exposure point of interest not supported on this device")
            return
        }

        do {
            try device.lockForConfiguration()

            // Set the metering point
            device.exposurePointOfInterest = zone.point

            // Must set exposure mode for the point to take effect
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            } else if device.isExposureModeSupported(.autoExpose) {
                device.exposureMode = .autoExpose
            }

            device.unlockForConfiguration()
        } catch {
            print("Could not apply metering zone: \(error.localizedDescription)")
        }
    }

    // MARK: - Session Control

    /// Start the capture session on a background thread
    func startSession() {
        guard !captureSession.isRunning else { return }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    /// Stop the capture session
    func stopSession() {
        guard captureSession.isRunning else { return }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.stopRunning()
        }
    }

    // MARK: - Lens Switching

    /// Switch to a different camera lens
    /// - Parameter lens: The lens to switch to
    /// - Note: Cannot be called while recording. Causes brief preview interruption.
    func switchCamera(to lens: CameraLens) {
        // Don't switch while recording
        guard !isRecording else { return }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // Get the new camera device
            guard let newDevice = AVCaptureDevice.default(
                lens.deviceType,
                for: .video,
                position: .back
            ) else {
                DispatchQueue.main.async {
                    self.error = .cameraNotAvailable(lens.label)
                }
                return
            }

            // Reconfigure the session
            self.captureSession.beginConfiguration()

            // Remove existing video input
            if let currentInput = self.captureSession.inputs.first as? AVCaptureDeviceInput {
                self.captureSession.removeInput(currentInput)
            }

            // Configure new device for 4K 30fps
            self.configure4K30fps(device: newDevice)

            // Add new input
            do {
                let newInput = try AVCaptureDeviceInput(device: newDevice)
                if self.captureSession.canAddInput(newInput) {
                    self.captureSession.addInput(newInput)
                    self.videoDevice = newDevice

                    // Track current lens
                    DispatchQueue.main.async {
                        self.currentLens = lens
                    }

                    // CRITICAL: Ensure stabilization stays OFF for maximum FOV
                    if let connection = self.videoOutput?.connection(with: .video) {
                        if connection.isVideoStabilizationSupported {
                            connection.preferredVideoStabilizationMode = .off
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.error = .cannotAddInput
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = .inputCreationFailed(error.localizedDescription)
                }
            }

            self.captureSession.commitConfiguration()
        }
    }

    // MARK: - Max FOV Mode

    /// Enable or disable Maximum FOV mode
    /// When enabled:
    /// - Disables geometric distortion correction (critical for fisheye lenses)
    /// - Uses inputPriority session preset for maximum control
    /// - Selects format with highest field of view
    /// - Parameter enabled: Whether to enable Max FOV mode
    /// - Parameter lens: Current lens (needed if we need to reconfigure)
    func setMaxFOVMode(_ enabled: Bool, lens: CameraLens) {
        guard enabled != maxFOVEnabled else { return }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            self.captureSession.beginConfiguration()

            // Update session preset based on mode
            // inputPriority tells iOS "I'll choose the format myself"
            if enabled {
                self.captureSession.sessionPreset = .inputPriority
            } else {
                self.captureSession.sessionPreset = .high
            }

            // Reconfigure device with appropriate format
            if let device = self.videoDevice {
                if enabled {
                    self.configureMaxFOVFormat(device: device)
                } else {
                    self.configure4K30fps(device: device)
                }

                // Apply/remove geometric distortion correction
                self.setGeometricDistortionCorrection(device: device, enabled: !enabled)
            }

            // Ensure stabilization stays OFF regardless of mode
            if let connection = self.videoOutput?.connection(with: .video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .off
                }
            }

            self.captureSession.commitConfiguration()

            DispatchQueue.main.async {
                self.maxFOVEnabled = enabled
            }
        }
    }

    /// Configure device for maximum field of view
    /// Prioritizes FOV over resolution - may result in less than 4K
    private func configureMaxFOVFormat(device: AVCaptureDevice) {
        // Find format with maximum field of view that supports at least 30fps
        let targetFrameRate: Float64 = 30.0

        let supportedFormats = device.formats.filter { format in
            // Must support at least 30fps
            format.videoSupportedFrameRateRanges.contains { range in
                range.maxFrameRate >= targetFrameRate
            }
        }

        // Find format with highest FOV
        // Note: We check both raw FOV and GDC-corrected FOV
        guard let bestFormat = supportedFormats.max(by: { format1, format2 in
            format1.videoFieldOfView < format2.videoFieldOfView
        }) else {
            print("Could not find suitable max FOV format, using default")
            return
        }

        let dimensions = CMVideoFormatDescriptionGetDimensions(bestFormat.formatDescription)
        print("Max FOV format selected: \(dimensions.width)x\(dimensions.height), FOV: \(bestFormat.videoFieldOfView)°")

        do {
            try device.lockForConfiguration()
            device.activeFormat = bestFormat

            // Set frame rate to 30fps
            let frameRateRange = bestFormat.videoSupportedFrameRateRanges.first { range in
                range.maxFrameRate >= targetFrameRate
            }

            if frameRateRange != nil {
                let duration = CMTime(value: 1, timescale: CMTimeScale(targetFrameRate))
                device.activeVideoMinFrameDuration = duration
                device.activeVideoMaxFrameDuration = duration
            }

            device.unlockForConfiguration()
        } catch {
            print("Could not configure max FOV format: \(error.localizedDescription)")
        }
    }

    /// Enable or disable geometric distortion correction
    /// Disabling GDC is CRITICAL for fisheye lenses - iOS normally "flattens" the edges
    private func setGeometricDistortionCorrection(device: AVCaptureDevice, enabled: Bool) {
        print("[GDC] Device: \(device.localizedName)")
        print("[GDC] Supported: \(device.isGeometricDistortionCorrectionSupported)")

        guard device.isGeometricDistortionCorrectionSupported else {
            print("[GDC] ⚠️ NOT SUPPORTED on this camera - Max FOV toggle has no effect")
            return
        }

        print("[GDC] Was: \(device.isGeometricDistortionCorrectionEnabled)")

        do {
            try device.lockForConfiguration()
            device.isGeometricDistortionCorrectionEnabled = enabled
            print("[GDC] Now: \(device.isGeometricDistortionCorrectionEnabled)")
            device.unlockForConfiguration()
        } catch {
            print("[GDC] Error: \(error.localizedDescription)")
        }
    }

    // MARK: - Recording

    /// Start recording video with current camera settings
    /// - Parameters:
    ///   - preset: The lighting preset currently selected
    ///   - settings: The camera settings being applied
    func startRecording(preset: CameraPreset, settings: CameraSettings) {
        guard let videoOutput = videoOutput, !isRecording else { return }

        // Set video rotation based on device orientation
        // This embeds rotation metadata in the video file for correct playback
        if let connection = videoOutput.connection(with: .video) {
            let orientation = UIDevice.current.orientation
            let rotationAngle: CGFloat
            switch orientation {
            case .portrait:
                rotationAngle = 90
            case .portraitUpsideDown:
                rotationAngle = 270
            case .landscapeLeft:
                rotationAngle = 0
            case .landscapeRight:
                rotationAngle = 180
            default:
                rotationAngle = 90  // Default to portrait
            }

            if connection.isVideoRotationAngleSupported(rotationAngle) {
                connection.videoRotationAngle = rotationAngle
            }
        }

        // Store metadata to save when recording completes
        currentRecordingMetadata = (preset, settings, currentLens, maxFOVEnabled)

        // Create unique filename with timestamp
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        let filename = "unoapp_\(timestamp).mov"

        // Save to Documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let outputURL = documentsPath.appendingPathComponent(filename)

        // Remove existing file if any
        try? FileManager.default.removeItem(at: outputURL)

        currentRecordingURL = outputURL
        recordingStartTime = Date()

        // Start recording
        videoOutput.startRecording(to: outputURL, recordingDelegate: self)

        DispatchQueue.main.async {
            self.isRecording = true
            self.startRecordingTimer()
        }
    }

    /// Stop the current recording
    func stopRecording() {
        guard let videoOutput = videoOutput, isRecording else { return }

        videoOutput.stopRecording()
        stopRecordingTimer()

        DispatchQueue.main.async {
            self.isRecording = false
            self.recordingDuration = 0
        }
    }

    // MARK: - Recording Timer

    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.recordingStartTime else { return }
            self.recordingDuration = Date().timeIntervalSince(startTime)
        }
    }

    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        recordingStartTime = nil
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate

extension CameraManager: AVCaptureFileOutputRecordingDelegate {

    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {

        if let error = error {
            currentRecordingMetadata = nil
            DispatchQueue.main.async {
                self.error = .recordingFailed(error.localizedDescription)
            }
            return
        }

        // Save metadata sidecar alongside the video
        if let (preset, settings, lens, maxFOV) = currentRecordingMetadata {
            let metadata = RecordingMetadata(preset: preset, settings: settings, lens: lens, maxFOV: maxFOV)
            saveMetadata(metadata, for: outputFileURL)
        }
        currentRecordingMetadata = nil

        // Notify that recording finished successfully
        DispatchQueue.main.async {
            self.onRecordingFinished?(outputFileURL)
        }
    }

    /// Save metadata JSON sidecar alongside the video file
    private func saveMetadata(_ metadata: RecordingMetadata, for videoURL: URL) {
        let metadataURL = videoURL.deletingPathExtension().appendingPathExtension("json")

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted  // Human-readable for field testing
            let data = try encoder.encode(metadata)
            try data.write(to: metadataURL)
        } catch {
            // Non-fatal: recording still saved, just without metadata
            print("Failed to save recording metadata: \(error.localizedDescription)")
        }
    }
}

// MARK: - Camera Errors

enum CameraError: LocalizedError {
    case noUltraWideCamera
    case cannotAddInput
    case cannotAddOutput
    case inputCreationFailed(String)
    case recordingFailed(String)
    case cameraNotAvailable(String)

    var errorDescription: String? {
        switch self {
        case .noUltraWideCamera:
            return "This device doesn't have an ultrawide camera. Unoapp requires an iPhone with an ultrawide lens."
        case .cannotAddInput:
            return "Cannot add camera input to the capture session."
        case .cannotAddOutput:
            return "Cannot add video output to the capture session."
        case .inputCreationFailed(let message):
            return "Failed to create camera input: \(message)"
        case .recordingFailed(let message):
            return "Recording failed: \(message)"
        case .cameraNotAvailable(let lens):
            return "The \(lens) camera is not available on this device."
        }
    }
}
