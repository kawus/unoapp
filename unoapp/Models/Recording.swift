//
//  Recording.swift
//  unoapp
//
//  Data model representing a recorded video with metadata.
//

import UIKit

/// Represents a recorded video file with its metadata
/// Identifiable: Required for SwiftUI List/ForEach
/// Hashable: Required for NavigationStack navigation
struct Recording: Identifiable, Hashable {

    let id: UUID
    let url: URL
    let filename: String
    let createdAt: Date
    var duration: TimeInterval
    var fileSize: Int64

    /// Thumbnail image (not included in Hashable)
    var thumbnail: UIImage?

    /// Camera settings used when recording (nil for legacy recordings)
    var metadata: RecordingMetadata?

    // MARK: - Hashable (exclude thumbnail since UIImage isn't Hashable)

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Recording, rhs: Recording) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Formatted Display Values

    /// Formatted duration for display (e.g., "02:34")
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Formatted file size for display (e.g., "124 MB")
    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    /// Formatted date for display (e.g., "Dec 5, 2025 at 3:42 PM")
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}
