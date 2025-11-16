import Foundation

/// Describes a previously exported file so it can be surfaced in "Recents".
///
/// The type is codable for persistence on disk and equatable so duplicates
/// can be filtered out when merging saved results. Each entry stores the
/// human-readable title and duration alongside the final file URL path and
/// its creation date.
struct RecentItem: Identifiable, Codable, Equatable {
    /// Stable identifier used for SwiftUI lists and persistence.
    let id: UUID
    /// User-facing title describing the export.
    let title: String
    /// Duration string displayed in the UI (e.g., formatted minutes/seconds).
    let duration: String
    /// Absolute path to the exported media file.
    let filePath: String
    /// Timestamp representing when the export finished.
    let createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        duration: String,
        fileURL: URL,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.duration = duration
        self.filePath = fileURL.path
        self.createdAt = createdAt
    }

    /// Convenience accessor that converts the stored path into a URL.
    var fileURL: URL {
        URL(fileURLWithPath: filePath)
    }
}

