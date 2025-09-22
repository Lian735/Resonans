import Foundation

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
