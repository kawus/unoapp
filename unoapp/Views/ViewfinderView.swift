//
//  ViewfinderView.swift
//  unoapp
//
//  Created by Kawus Nouri on 05/12/2025.
//
//  Main camera viewfinder screen with recording controls.
//  Designed for iOS 26 with Liquid Glass aesthetics.
//  Supports both portrait and landscape orientations.
//

import SwiftUI
import AVKit

/// Main viewfinder screen showing camera preview and recording controls
/// Design principles (iOS 26 Liquid Glass HIG):
/// - Camera preview is the hero content
/// - Controls float and recede during recording
/// - Minimal distractions, maximum focus on the footage
/// - Adapts to orientation: bottom controls (portrait), right edge (landscape)
struct ViewfinderView: View {

    @ObservedObject var viewModel: CameraViewModel

    /// Tracks device orientation for adaptive layout
    @State private var orientationManager = OrientationManager()

    /// Navigate to recordings list
    @State private var showRecordingsList = false

    /// Thumbnail of most recent recording
    @State private var lastThumbnail: UIImage?

    var body: some View {
        let isLandscape = orientationManager.isLandscape

        NavigationStack {
            ZStack {
                // Full-screen camera preview
                // Tap to dismiss manual controls panel and metering grid
                CameraPreviewView(session: viewModel.cameraManager.captureSession)
                    .ignoresSafeArea()
                    .onTapGesture {
                        viewModel.dismissManualControls()
                        if viewModel.showMeteringGrid {
                            viewModel.toggleMeteringGrid()
                        }
                    }

                // Metering grid overlay (when visible)
                if viewModel.showMeteringGrid {
                    MeteringGridOverlay(
                        selectedZone: $viewModel.manualSettings.meteringZone,
                        onZoneSelected: { zone in
                            viewModel.selectMeteringZone(zone)
                        }
                    )
                    .ignoresSafeArea()
                    .transition(.opacity)
                }

                // Main UI overlay
                VStack(spacing: 0) {
                    // Preset bar at top (always visible) with Max FOV toggle
                    PresetBar(
                        selectedPreset: $viewModel.selectedPreset,
                        maxFOVEnabled: viewModel.maxFOVEnabled,
                        isRecording: viewModel.isRecording,
                        onPresetSelected: { preset in
                            viewModel.selectPreset(preset)
                        },
                        onMaxFOVToggle: {
                            viewModel.toggleMaxFOV()
                        }
                    )

                    // Manual controls (shown when manual preset selected AND controls not dismissed)
                    if viewModel.selectedPreset == .manual && viewModel.showManualControls {
                        ManualControlsView(
                            settings: $viewModel.manualSettings,
                            onSettingsChanged: { settings in
                                viewModel.applyManualSettings(settings)
                            }
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    Spacer()
                }
                .animation(.easeInOut(duration: 0.2), value: viewModel.selectedPreset)
                .animation(.easeInOut(duration: 0.2), value: viewModel.showManualControls)
                .animation(.easeInOut(duration: 0.2), value: viewModel.showMeteringGrid)

                // Recording indicator - below preset bar
                if viewModel.isRecording {
                    VStack {
                        RecordingIndicator(duration: viewModel.formattedDuration)
                            .padding(.top, viewModel.showManualControls ? 180 : 100)
                        Spacer()
                    }
                    .transition(.opacity.combined(with: .scale))
                }

                // Adaptive toolbar with thumbnail + lens selector + record button + grid toggle
                // Portrait: lens selector above, thumbnail left, record centered, grid right
                // Landscape: thumbnail top, lens selector, record centered, grid bottom
                AdaptiveToolbar(
                    isLandscape: isLandscape,
                    thumbnail: lastThumbnail,
                    isRecording: viewModel.isRecording,
                    showMeteringGrid: viewModel.showMeteringGrid,
                    selectedLens: viewModel.selectedLens,
                    onThumbnailTap: { showRecordingsList = true },
                    onRecordTap: { viewModel.toggleRecording() },
                    onGridToggle: { viewModel.toggleMeteringGrid() },
                    onLensChange: { lens in viewModel.selectLens(lens) }
                )

                // Recording saved confirmation
                if viewModel.showRecordingSaved {
                    RecordingSavedToast()
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Error message
                if let error = viewModel.errorMessage {
                    ErrorBanner(message: error)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            // Handle volume buttons / Bluetooth remote / Camera Control for recording
            .onCameraCaptureEvent { event in
                if event.phase == .ended {
                    viewModel.toggleRecording()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.isRecording)
            .animation(.easeInOut(duration: 0.3), value: viewModel.showRecordingSaved)
            .animation(.easeInOut(duration: 0.3), value: viewModel.errorMessage)
            .animation(.easeInOut(duration: 0.2), value: isLandscape)
            .navigationDestination(isPresented: $showRecordingsList) {
                RecordingsListView()
            }
        }
        .onAppear {
            viewModel.setupCamera()
            loadLastThumbnail()
        }
        .onDisappear {
            viewModel.stopCamera()
        }
        // Update thumbnail when a new recording is saved
        .onChange(of: viewModel.showRecordingSaved) { _, saved in
            if saved {
                // Delay slightly to ensure file is written
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    loadLastThumbnail()
                }
            }
        }
    }

    /// Load thumbnail of most recent recording
    private func loadLastThumbnail() {
        Task { @MainActor in
            let storage = RecordingStorage()
            await storage.loadRecordings()
            if let recent = storage.mostRecentRecording {
                lastThumbnail = recent.thumbnail
            }
        }
    }
}

// MARK: - Recording Indicator

/// Shows current recording time with pulsing red dot
struct RecordingIndicator: View {

    let duration: String
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 8) {
            // Pulsing red dot
            Circle()
                .fill(.red)
                .frame(width: 12, height: 12)
                .scaleEffect(isPulsing ? 1.2 : 1.0)
                .animation(
                    .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                    value: isPulsing
                )

            // Duration text
            Text(duration)
                .font(.system(size: 17, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .onAppear {
            isPulsing = true
        }
    }
}

// MARK: - Record Button

/// Large circular record button with stop/record states
/// Includes haptic feedback on tap for tactile confirmation
struct RecordButton: View {

    let isRecording: Bool
    let action: () -> Void

    var body: some View {
        Button {
            // Trigger haptic BEFORE action for instant feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        } label: {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(.white, lineWidth: 4)
                    .frame(width: 72, height: 72)

                // Inner shape - circle when ready, rounded square when recording
                if isRecording {
                    // Stop button (rounded square)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.red)
                        .frame(width: 28, height: 28)
                } else {
                    // Record button (filled circle)
                    Circle()
                        .fill(.red)
                        .frame(width: 58, height: 58)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isRecording)
        // Additional haptic when recording state actually changes
        .sensoryFeedback(.impact(flexibility: .rigid), trigger: isRecording)
    }
}

// MARK: - Recording Saved Toast

/// Brief confirmation toast when recording is saved
struct RecordingSavedToast: View {

    var body: some View {
        VStack {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Recording Saved")
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.top, 60)

            Spacer()
        }
    }
}

// MARK: - Error Banner

/// Error message banner at top of screen
struct ErrorBanner: View {

    let message: String

    var body: some View {
        VStack {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.red.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 20)
            .padding(.top, 60)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    ViewfinderView(viewModel: CameraViewModel())
}
