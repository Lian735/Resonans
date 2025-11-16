import Foundation

/// Represents a recently converted audio file with metadata.
///
/// `RecentItem` stores information about a completed audio conversion, including:
/// - Unique identifier for list management
/// - Display title (typically the original filename)
/// - Duration string (e.g., "5:30")
/// - File path to the exported audio file
/// - Creation timestamp
///
/// The struct provides both file path (for persistence) and file URL (for access) properties.
///
/// Example usage:
/// ```swift
/// let item = RecentItem(
///     title: "My Video",
///     duration: "5:30",
///     fileURL: exportedAudioURL
/// )
/// ```
///
/// - Note: Conforms to `Codable` for JSON persistence and `Equatable` for list comparison
struct RecentItem: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let duration: String
    let filePath: String
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

    var fileURL: URL {
        URL(fileURLWithPath: filePath)
    }
}

