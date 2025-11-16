import Foundation

/// Represents a news item displayed in the app.
///
/// `AppNewsItem` is used to show updates, announcements, or important information to users.
/// Each item has a unique identifier, title, description, and publication date.
///
/// The ``formattedDate`` property provides a localized, user-friendly date string.
///
/// Example usage:
/// ```swift
/// let newsItem = AppNewsItem(
///     title: "New Feature: Background Remover",
///     description: "Remove backgrounds from your images with AI",
///     date: Date()
/// )
/// ```
struct AppNewsItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let date: Date

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
