import Foundation

/// Represents a single announcement displayed in the app's news feed.
///
/// Each item is identified by a generated `UUID` and includes a title,
/// description, and publication date. The `formattedDate` helper renders
/// the date using the user’s locale-friendly medium style to match the
/// rest of the interface.
struct AppNewsItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let date: Date

    /// Returns the localized display string for the publication date.
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
