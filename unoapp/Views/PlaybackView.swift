//
//  PlaybackView.swift
//  unoapp
//
//  Full-screen video playback view.
//  Features: native video controls, share/export, delete.
//

import SwiftUI
import AVKit

// MARK: - AVPlayerViewController Wrapper

/// Wraps AVPlayerViewController for SwiftUI - respects video rotation metadata
struct VideoPlayerView: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        // Player already set
    }
}

/// Full-screen video playback view
struct PlaybackView: View {

    let recording: Recording
    let storage: RecordingStorage

    @State private var player: AVPlayer?
    @State private var isExporting = false
    @State private var showExportSuccess = false
    @State private var showDeleteConfirmation = false
    @State private var errorMessage: String?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header with date and settings
            recordingHeader
                .padding(.horizontal)
                .padding(.vertical, 8)

            // Video player
            ZStack {
                if let player = player {
                    VideoPlayerView(player: player)
                } else {
                    ProgressView()
                }

                // Export success toast
                if showExportSuccess {
                    VStack {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Saved to Camera Roll")
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.top, 16)

                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        exportToCameraRoll()
                    } label: {
                        Label("Save to Camera Roll", systemImage: "square.and.arrow.down")
                    }

                    ShareLink(item: recording.url) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            player = AVPlayer(url: recording.url)
            player?.play()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
        .alert("Delete Recording?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAndDismiss()
            }
        } message: {
            Text("This cannot be undone.")
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showExportSuccess)
    }

    // MARK: - Recording Header

    private var recordingHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Date and duration
            HStack {
                Text(recording.formattedDate)
                    .font(.headline)
                Spacer()
                Text(recording.formattedDuration)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Settings (if available)
            if let metadata = recording.metadata {
                HStack(spacing: 16) {
                    ForEach(metadata.detailLines, id: \.label) { item in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.label)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Text(item.value)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Actions

    private func exportToCameraRoll() {
        Task {
            isExporting = true
            do {
                try await storage.exportToCameraRoll(recording)
                showExportSuccess = true

                // Hide after 2 seconds
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                showExportSuccess = false
            } catch {
                errorMessage = error.localizedDescription
            }
            isExporting = false
        }
    }

    private func deleteAndDismiss() {
        do {
            try storage.deleteRecording(recording)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PlaybackView(
            recording: Recording(
                id: UUID(),
                url: URL(fileURLWithPath: "/tmp/test.mov"),
                filename: "test.mov",
                createdAt: Date(),
                duration: 125,
                fileSize: 52_428_800,
                thumbnail: nil
            ),
            storage: RecordingStorage()
        )
    }
}
