import Foundation

final class CacheManager {
    static let shared = CacheManager()
    private init() {}

    /// Clears any cached network responses.
    func clear() {
        URLCache.shared.removeAllCachedResponses()
        CacheFile.allCases.forEach { file in
            if let url = cacheURL(for: file) {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    private enum CacheFile: String, CaseIterable {
        case recentTools = "recent_tools.json"
        case audioRecents = "audio_recents.json"
    }

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private func cacheURL(for file: CacheFile) -> URL? {
        guard let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        return cachesDirectory.appendingPathComponent(file.rawValue)
    }

    func loadRecentTools() -> [ToolItem.Identifier] {
        guard
            let url = cacheURL(for: .recentTools),
            let data = try? Data(contentsOf: url),
            let rawValues = try? decoder.decode([String].self, from: data)
        else {
            return []
        }

        return rawValues.compactMap { ToolItem.Identifier(rawValue: $0) }
    }

    func saveRecentTools(_ identifiers: [ToolItem.Identifier]) {
        guard let url = cacheURL(for: .recentTools) else { return }
        let rawValues = identifiers.map { $0.rawValue }
        guard let data = try? encoder.encode(rawValues) else { return }
        try? data.write(to: url, options: [.atomic])
    }

    func loadRecentConversions() -> [RecentItem] {
        guard
            let url = cacheURL(for: .audioRecents),
            let data = try? Data(contentsOf: url),
            let items = try? decoder.decode([RecentItem].self, from: data)
        else {
            return []
        }
        return items
    }

    func saveRecentConversions(_ items: [RecentItem]) {
        guard let url = cacheURL(for: .audioRecents) else { return }
        guard let data = try? encoder.encode(items) else { return }
        try? data.write(to: url, options: [.atomic])
    }
}
