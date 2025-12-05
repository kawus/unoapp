//
//  ViewfinderView.swift
//  unoapp
//
//  Created by Kawus Nouri on 05/12/2025.
//
//  Main camera viewfinder screen with recording controls.
//  Designed for iOS 26 with Liquid Glass aesthetics.
//

import SwiftUI

/// Main viewfinder screen showing camera preview and recording controls
/// Design principles (iOS 26 Liquid Glass HIG):
/// - Camera preview is the hero content
/// - Controls float and recede during recording
/// - Minimal distractions, maximum focus on the footage
struct ViewfinderView: View {

    @ObservedObject var viewModel: CameraViewModel

    var body: some View {
        ZStack {
            // Full-screen camera preview
            CameraPreviewView(session: viewModel.cameraManager.captureSession)
                .ignoresSafeArea()

            // Overlay controls
            VStack {
                Spacer()

                // Recording duration (only visible when recording)
                if viewModel.isRecording {
                    RecordingIndicator(duration: viewModel.formattedDuration)
                        .transition(.opacity.combined(with: .scale))
                }

                Spacer()

                // Bottom toolbar with record button
                BottomToolbar(
                    isRecording: viewModel.isRecording,
                    onRecordTap: { viewModel.toggleRecording() }
                )
                .padding(.bottom, 30)
            }

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
        .animation(.easeInOut(duration: 0.3), value: viewModel.isRecording)
        .animation(.easeInOut(duration: 0.3), value: viewModel.showRecordingSaved)
        .animation(.easeInOut(duration: 0.3), value: viewModel.errorMessage)
        .onAppear {
            viewModel.setupCamera()
        }
        .onDisappear {
            viewModel.stopCamera()
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

// MARK: - Bottom Toolbar

/// Floating toolbar with record button
/// Uses Liquid Glass material for iOS 26
struct BottomToolbar: View {

    let isRecording: Bool
    let onRecordTap: () -> Void

    var body: some View {
        HStack {
            Spacer()

            // Record button
            RecordButton(isRecording: isRecording, action: onRecordTap)

            Spacer()
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 20)
        .background(.ultraThinMaterial, in: Capsule())
        .padding(.horizontal, 20)
    }
}

// MARK: - Record Button

/// Large circular record button with stop/record states
struct RecordButton: View {

    let isRecording: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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
