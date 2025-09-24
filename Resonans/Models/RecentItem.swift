import Foundation

struct RecentItem: Identifiable, Codable {
    let id: UUID
    let title: String
    let duration: TimeInterval
    let fileURL: URL
    let createdAt: Date

    init(id: UUID = UUID(), title: String, duration: TimeInterval, fileURL: URL, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.duration = duration
        self.fileURL = fileURL
        self.createdAt = createdAt
    }

    var formattedDuration: String {
        guard duration.isFinite, duration > 0 else {
            return "Unknown length"
        }
        let totalSeconds = Int(duration.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

