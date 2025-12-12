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
    @Published var debugInfo: CameraDebugInfo?

    // MARK: - Camera Session

    let captureSession = AVCaptureSession()
    private var videoOutput: AVCaptureMovieFileOutput?
    private var videoDevice: AVCaptureDevice?
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?

    // MARK: - Recording Storage

    private var currentRecordingURL: URL?
    private var currentRecordingMetadata: (preset: CameraPreset, settings: CameraSettings, lens: CameraLens, maxFOV: Bool, aspectRatio: AspectRatio)?
    var onRecordingFinished: ((URL) -> Void)?

    /// Currently active camera lens
    private(set) var currentLens: CameraLens = .ultraWide

    /// Whether Max FOV mode is enabled (disables distortion correction, selects max FOV format)
    private(set) var maxFOVEnabled: Bool = false

    /// Current aspect ratio for video capture
    private(set) var currentAspectRatio: AspectRatio = .sixteenByNine

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

        // Update debug info after setup
        updateDebugInfo()
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

            // Update debug info after lens switch
            self.updateDebugInfo()
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
                    // Disable ALL frame-cropping features for maximum FOV
                    self.disableAllFrameCroppingFeatures(device: device)
                } else {
                    self.configure4K30fps(device: device)
                    // Re-enable GDC for standard mode (gives cleaner image)
                    self.setGeometricDistortionCorrection(device: device, enabled: true)
                }
            }

            // Ensure stabilization stays OFF regardless of mode
            if let connection = self.videoOutput?.connection(with: .video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .off
                }
            }

            self.captureSession.commitConfiguration()

            // Update debug info after Max FOV toggle
            self.updateDebugInfo()

            DispatchQueue.main.async {
                self.maxFOVEnabled = enabled
            }
        }
    }

    /// Configure device for maximum field of view
    /// Prioritizes FOV over resolution - may result in less than 4K
    /// Filters by current aspect ratio (4:3 captures more of circular fisheye projection)
    private func configureMaxFOVFormat(device: AVCaptureDevice) {
        let targetFrameRate: Float64 = 30.0

        // Filter formats that support 30fps
        var supportedFormats = device.formats.filter { format in
            format.videoSupportedFrameRateRanges.contains { range in
                range.maxFrameRate >= targetFrameRate
            }
        }

        // Filter by aspect ratio if not 16:9 (16:9 is the default, most formats support it)
        if currentAspectRatio == .fourByThree {
            let filtered = supportedFormats.filter { format in
                let dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                let ratio = Float(dims.width) / Float(dims.height)
                // 4:3 = 1.333... Allow small tolerance
                return abs(ratio - 1.333) < 0.05
            }
            if !filtered.isEmpty {
                supportedFormats = filtered
                print("[MaxFOV] Filtering for 4:3 formats, found \(filtered.count) options")
            } else {
                print("[MaxFOV] No 4:3 formats found, using best available")
            }
        }

        // Sort by: FOV (highest first), then resolution (highest first for tie-breaking)
        let sortedFormats = supportedFormats.sorted { f1, f2 in
            if f1.videoFieldOfView != f2.videoFieldOfView {
                return f1.videoFieldOfView > f2.videoFieldOfView
            }
            let dims1 = CMVideoFormatDescriptionGetDimensions(f1.formatDescription)
            let dims2 = CMVideoFormatDescriptionGetDimensions(f2.formatDescription)
            return (dims1.width * dims1.height) > (dims2.width * dims2.height)
        }

        guard let bestFormat = sortedFormats.first else {
            print("[MaxFOV] No suitable format found, using default")
            return
        }

        let dimensions = CMVideoFormatDescriptionGetDimensions(bestFormat.formatDescription)
        let ratio = Float(dimensions.width) / Float(dimensions.height)
        print("[MaxFOV] Selected: \(dimensions.width)x\(dimensions.height), FOV: \(bestFormat.videoFieldOfView)°, Ratio: \(String(format: "%.2f", ratio))")

        do {
            try device.lockForConfiguration()
            device.activeFormat = bestFormat

            // CRITICAL: Ensure zoom is at 1.0 to prevent any digital cropping
            device.videoZoomFactor = 1.0

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
            print("[MaxFOV] Config error: \(error.localizedDescription)")
        }
    }

    // MARK: - Aspect Ratio

    /// Set the aspect ratio for video capture
    /// - Parameter ratio: The desired aspect ratio
    /// - Note: Cannot be called while recording. Reconfigures camera format.
    func setAspectRatio(_ ratio: AspectRatio) {
        guard ratio != currentAspectRatio else { return }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            self.captureSession.beginConfiguration()

            // Update aspect ratio first so format selection uses it
            let oldRatio = self.currentAspectRatio
            self.currentAspectRatio = ratio

            // Reconfigure device with new aspect ratio
            if let device = self.videoDevice {
                if self.maxFOVEnabled {
                    self.configureMaxFOVFormat(device: device)
                } else {
                    // For standard mode, also respect aspect ratio
                    self.configureStandardFormat(device: device)
                }
            }

            self.captureSession.commitConfiguration()

            // Update debug info after aspect ratio change
            self.updateDebugInfo()

            DispatchQueue.main.async {
                print("[AspectRatio] Changed from \(oldRatio.label) to \(ratio.label)")
            }
        }
    }

    /// Configure standard format (non-Max FOV) with aspect ratio support
    private func configureStandardFormat(device: AVCaptureDevice) {
        let targetFrameRate: Float64 = 30.0

        // Start with formats that support 30fps
        var supportedFormats = device.formats.filter { format in
            format.videoSupportedFrameRateRanges.contains { range in
                range.maxFrameRate >= targetFrameRate
            }
        }

        // Filter by aspect ratio
        if currentAspectRatio == .fourByThree {
            let filtered = supportedFormats.filter { format in
                let dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                let ratio = Float(dims.width) / Float(dims.height)
                return abs(ratio - 1.333) < 0.05
            }
            if !filtered.isEmpty {
                supportedFormats = filtered
            }
        } else {
            // 16:9 formats
            let filtered = supportedFormats.filter { format in
                let dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                let ratio = Float(dims.width) / Float(dims.height)
                return abs(ratio - 1.778) < 0.05  // 16:9 = 1.777...
            }
            if !filtered.isEmpty {
                supportedFormats = filtered
            }
        }

        // Sort by resolution (highest first)
        let sortedFormats = supportedFormats.sorted { f1, f2 in
            let dims1 = CMVideoFormatDescriptionGetDimensions(f1.formatDescription)
            let dims2 = CMVideoFormatDescriptionGetDimensions(f2.formatDescription)
            return (dims1.width * dims1.height) > (dims2.width * dims2.height)
        }

        guard let bestFormat = sortedFormats.first else {
            print("[Standard] No suitable format found")
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
            print("[Standard] Config error: \(error.localizedDescription)")
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

    /// Disable all features that crop the frame for maximum FOV
    /// Called when Max FOV mode is enabled to ensure nothing reduces the captured area
    private func disableAllFrameCroppingFeatures(device: AVCaptureDevice) {
        // 1. Disable Geometric Distortion Correction (most important for fisheye)
        setGeometricDistortionCorrection(device: device, enabled: false)

        // 2. Disable Center Stage (auto-framing that crops to follow subjects)
        // Center Stage is a class-level setting, not per-device
        if AVCaptureDevice.isCenterStageEnabled {
            print("[FOV] Disabling Center Stage")
            AVCaptureDevice.centerStageControlMode = .user
            AVCaptureDevice.isCenterStageEnabled = false
        }

        // 3. Ensure zoom is at minimum (no digital cropping)
        do {
            try device.lockForConfiguration()
            if device.videoZoomFactor != 1.0 {
                print("[FOV] Resetting zoom from \(device.videoZoomFactor) to 1.0")
                device.videoZoomFactor = 1.0
            }
            device.unlockForConfiguration()
        } catch {
            print("[FOV] Error setting zoom: \(error.localizedDescription)")
        }
    }

    // MARK: - Debug Info

    /// Update debug info for on-screen overlay
    /// Call this after any camera configuration change
    func updateDebugInfo() {
        guard let device = videoDevice else { return }

        let format = device.activeFormat
        let dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription)

        // Calculate aspect ratio
        let aspectRatio = calculateAspectRatio(width: Int(dims.width), height: Int(dims.height))

        // Get stabilization mode from output connection
        let stabMode: String
        if let conn = videoOutput?.connection(with: .video) {
            stabMode = describeStabilizationMode(conn.activeVideoStabilizationMode)
        } else {
            stabMode = "unknown"
        }

        // Calculate actual frame rate
        let frameRate = Float(1.0 / CMTimeGetSeconds(device.activeVideoMinFrameDuration))

        let info = CameraDebugInfo(
            resolution: "\(dims.width)x\(dims.height)",
            videoFieldOfView: format.videoFieldOfView,
            frameRate: frameRate,
            aspectRatio: aspectRatio,
            gdcEnabled: device.isGeometricDistortionCorrectionSupported ?
                        device.isGeometricDistortionCorrectionEnabled : false,
            gdcSupported: device.isGeometricDistortionCorrectionSupported,
            stabilizationMode: stabMode,
            sessionPreset: describeSessionPreset(captureSession.sessionPreset),
            lens: currentLens == .wide ? "Wide (1x)" : "Ultra Wide (0.5x)",
            videoZoomFactor: Float(device.videoZoomFactor),
            maxFOVEnabled: maxFOVEnabled
        )

        DispatchQueue.main.async {
            self.debugInfo = info
        }
    }

    /// Calculate human-readable aspect ratio from dimensions
    private func calculateAspectRatio(width: Int, height: Int) -> String {
        func gcd(_ a: Int, _ b: Int) -> Int {
            b == 0 ? a : gcd(b, a % b)
        }
        let divisor = gcd(width, height)
        let w = width / divisor
        let h = height / divisor

        // Simplify common ratios
        if w == 16 && h == 9 { return "16:9" }
        if w == 4 && h == 3 { return "4:3" }
        if w == 3 && h == 2 { return "3:2" }
        return "\(w):\(h)"
    }

    /// Convert stabilization mode to readable string
    private func describeStabilizationMode(_ mode: AVCaptureVideoStabilizationMode) -> String {
        switch mode {
        case .off: return "off"
        case .standard: return "standard"
        case .cinematic: return "cinematic"
        case .cinematicExtended: return "cinematicExt"
        case .auto: return "auto"
        case .previewOptimized: return "preview"
        @unknown default: return "unknown"
        }
    }

    /// Convert session preset to readable string
    private func describeSessionPreset(_ preset: AVCaptureSession.Preset) -> String {
        switch preset {
        case .inputPriority: return "inputPriority"
        case .high: return "high"
        case .medium: return "medium"
        case .low: return "low"
        case .photo: return "photo"
        case .hd4K3840x2160: return "4K"
        case .hd1920x1080: return "1080p"
        case .hd1280x720: return "720p"
        default: return "other"
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
        currentRecordingMetadata = (preset, settings, currentLens, maxFOVEnabled, currentAspectRatio)

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
        if let (preset, settings, lens, maxFOV, aspectRatio) = currentRecordingMetadata {
            let metadata = RecordingMetadata(preset: preset, settings: settings, lens: lens, maxFOV: maxFOV, aspectRatio: aspectRatio)
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
