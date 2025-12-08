//
//  RecordingsListView.swift
//  unoapp
//
//  List view showing all recorded videos with thumbnails.
//  Features: tap to play, swipe to delete, empty state.
//

import SwiftUI

/// List view showing all recorded videos
struct RecordingsListView: View {

    @State private var storage = RecordingStorage()
    @State private var selectedRecording: Recording?
    @State private var showDeleteConfirmation = false
    @State private var recordingToDelete: Recording?

    var body: some View {
        Group {
            if storage.isLoading {
                ProgressView("Loading recordings...")
            } else if storage.recordings.isEmpty {
                EmptyRecordingsView()
            } else {
                recordingsList
            }
        }
        .navigationTitle("Recordings")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await storage.loadRecordings()
        }
        .navigationDestination(item: $selectedRecording) { recording in
            PlaybackView(recording: recording, storage: storage)
        }
        .alert("Delete Recording?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let recording = recordingToDelete {
                    deleteRecording(recording)
                }
            }
        } message: {
            Text("This cannot be undone.")
        }
    }

    private var recordingsList: some View {
        List {
            ForEach(storage.recordings) { recording in
                RecordingRow(recording: recording)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedRecording = recording
                    }
            }
            .onDelete { indexSet in
                if let index = indexSet.first {
                    recordingToDelete = storage.recordings[index]
                    showDeleteConfirmation = true
                }
            }
        }
        .listStyle(.plain)
    }

    private func deleteRecording(_ recording: Recording) {
        do {
            try storage.deleteRecording(recording)
        } catch {
            storage.errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Recording Row

/// Row component showing a single recording with thumbnail
struct RecordingRow: View {

    let recording: Recording

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let thumbnail = recording.thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                // Placeholder when thumbnail not available
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 60)
                    .overlay {
                        Image(systemName: "video.fill")
                            .foregroundStyle(.secondary)
                    }
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(recording.formattedDate)
                    .font(.headline)

                HStack(spacing: 8) {
                    Label(recording.formattedDuration, systemImage: "clock")
                    Label(recording.formattedFileSize, systemImage: "doc")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Empty State

/// Empty state shown when no recordings exist
struct EmptyRecordingsView: View {

    var body: some View {
        ContentUnavailableView(
            "No Recordings",
            systemImage: "video.slash",
            description: Text("Videos you record will appear here.")
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RecordingsListView()
    }
}
