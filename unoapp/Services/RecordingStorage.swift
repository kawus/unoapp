//
//  RecordingStorage.swift
//  unoapp
//
//  Manages recording files in the Documents directory.
//  Handles: scanning, thumbnails, deletion, and Camera Roll export.
//

import AVFoundation
import Photos
import UIKit

/// Manages recording files stored in the app's Documents directory
@Observable
final class RecordingStorage {

    /// All loaded recordings, sorted by date (newest first)
    var recordings: [Recording] = []

    /// True while scanning directory or loading metadata
    var isLoading = false

    /// Error message if something goes wrong
    var errorMessage: String?

    private let fileManager = FileManager.default

    // MARK: - Load Recordings

    /// Scan Documents directory for unoapp recordings
    @MainActor
    func loadRecordings() async {
        isLoading = true
        defer { isLoading = false }

        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

        do {
            let files = try fileManager.contentsOfDirectory(
                at: documentsURL,
                includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
                options: .skipsHiddenFiles
            )

            // Filter for unoapp_*.mov files
            let movFiles = files.filter {
                $0.lastPathComponent.hasPrefix("unoapp_") &&
                $0.pathExtension.lowercased() == "mov"
            }

            // Create Recording objects with metadata
            var loadedRecordings: [Recording] = []
            for url in movFiles {
                if let recording = await createRecording(from: url) {
                    loadedRecordings.append(recording)
                }
            }

            // Sort by date, newest first
            recordings = loadedRecordings.sorted { $0.createdAt > $1.createdAt }

        } catch {
            errorMessage = "Failed to load recordings: \(error.localizedDescription)"
        }
    }

    // MARK: - Create Recording from URL

    /// Create a Recording object from a file URL
    private func createRecording(from url: URL) async -> Recording? {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            let creationDate = attributes[.creationDate] as? Date ?? Date()
            let fileSize = attributes[.size] as? Int64 ?? 0

            // Get video duration (using AVURLAsset for iOS 18+)
            let asset = AVURLAsset(url: url)
            let duration = try await asset.load(.duration)
            let durationSeconds = CMTimeGetSeconds(duration)

            // Generate thumbnail
            let thumbnail = await generateThumbnail(for: url)

            return Recording(
                id: UUID(),
                url: url,
                filename: url.lastPathComponent,
                createdAt: creationDate,
                duration: durationSeconds.isNaN ? 0 : durationSeconds,
                fileSize: fileSize,
                thumbnail: thumbnail
            )
        } catch {
            print("Failed to create recording from \(url): \(error)")
            return nil
        }
    }

    // MARK: - Thumbnail Generation

    /// Generate a thumbnail image from a video file
    func generateThumbnail(for url: URL) async -> UIImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 200, height: 200)

        do {
            let (cgImage, _) = try await generator.image(at: .zero)
            return UIImage(cgImage: cgImage)
        } catch {
            print("Thumbnail generation failed: \(error)")
            return nil
        }
    }

    // MARK: - Delete Recording

    /// Delete a recording from disk
    func deleteRecording(_ recording: Recording) throws {
        try fileManager.removeItem(at: recording.url)
        recordings.removeAll { $0.id == recording.id }
    }

    // MARK: - Export to Camera Roll

    /// Export recording to Camera Roll
    func exportToCameraRoll(_ recording: Recording) async throws {
        // Request permission if needed
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw RecordingStorageError.photoLibraryAccessDenied
        }

        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: recording.url)
        }
    }

    // MARK: - Helpers

    /// Get the most recent recording (for thumbnail button on camera view)
    var mostRecentRecording: Recording? {
        recordings.first
    }
}

// MARK: - Errors

enum RecordingStorageError: LocalizedError {
    case photoLibraryAccessDenied

    var errorDescription: String? {
        switch self {
        case .photoLibraryAccessDenied:
            return "Photo library access is required to save videos to your Camera Roll."
        }
    }
}
