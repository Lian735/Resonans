import Foundation

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

