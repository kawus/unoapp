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
    var onRecordingFinished: ((URL) -> Void)?

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

    // MARK: - Recording

    /// Start recording video to a temporary file
    func startRecording() {
        guard let videoOutput = videoOutput, !isRecording else { return }

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
            DispatchQueue.main.async {
                self.error = .recordingFailed(error.localizedDescription)
            }
            return
        }

        // Notify that recording finished successfully
        DispatchQueue.main.async {
            self.onRecordingFinished?(outputFileURL)
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
        }
    }
}
