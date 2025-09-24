import Foundation

final class CacheManager {
    static let shared = CacheManager()

    private let fileManager = FileManager.default
    private let baseDirectory: URL
    private let exportsDirectory: URL
    private let recentToolsURL: URL
    private let recentConversionsURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private let maxRecentTools = 6
    private let maxRecentConversions = 10

    private init() {
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        baseDirectory = cachesDirectory.appendingPathComponent("com.resonans.cache", isDirectory: true)
        exportsDirectory = baseDirectory.appendingPathComponent("exports", isDirectory: true)
        recentToolsURL = baseDirectory.appendingPathComponent("recent-tools.json")
        recentConversionsURL = baseDirectory.appendingPathComponent("recent-conversions.json")

        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        createDirectoriesIfNeeded()
    }

    /// Clears any cached network responses and stored files created by the app.
    func clear() {
        URLCache.shared.removeAllCachedResponses()
        try? fileManager.removeItem(at: baseDirectory)
        createDirectoriesIfNeeded()
    }

    // MARK: - Recent tools

    func loadRecentTools() -> [ToolItem.Identifier] {
        guard let data = try? Data(contentsOf: recentToolsURL) else { return [] }
        guard let rawIDs = try? decoder.decode([String].self, from: data) else {
            try? fileManager.removeItem(at: recentToolsURL)
            return []
        }
        return rawIDs.compactMap { ToolItem.Identifier(rawValue: $0) }
    }

    func saveRecentTools(_ identifiers: [ToolItem.Identifier]) {
        let trimmed = Array(identifiers.prefix(maxRecentTools))
        let raw = trimmed.map { $0.rawValue }
        guard let data = try? encoder.encode(raw) else { return }
        try? data.write(to: recentToolsURL, options: .atomic)
    }

    // MARK: - Recent conversions

    func loadRecentConversions() -> [RecentItem] {
        guard let data = try? Data(contentsOf: recentConversionsURL) else { return [] }
        guard let decoded = try? decoder.decode([RecentItem].self, from: data) else {
            try? fileManager.removeItem(at: recentConversionsURL)
            return []
        }

        let existing = decoded.filter { fileManager.fileExists(atPath: $0.filePath) }
        if existing.count != decoded.count {
            saveRecentConversions(existing)
        }
        return existing
    }

    @discardableResult
    func recordConversion(title: String, duration: String, tempURL: URL) throws -> RecentItem {
        createDirectoriesIfNeeded()

        let destination = try uniqueDestination(for: tempURL)

        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }

        try fileManager.moveItem(at: tempURL, to: destination)

        var items = loadRecentConversions()
        let newItem = RecentItem(title: title, duration: duration, fileURL: destination, createdAt: Date())

        items.removeAll(where: { $0.id == newItem.id || $0.filePath == newItem.filePath })
        items.insert(newItem, at: 0)

        if items.count > maxRecentConversions {
            let overflow = items.suffix(from: maxRecentConversions)
            overflow.forEach { try? fileManager.removeItem(atPath: $0.filePath) }
            items = Array(items.prefix(maxRecentConversions))
        }

        saveRecentConversions(items)

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .recentConversionsDidUpdate, object: items)
        }

        return newItem
    }

    // MARK: - Helpers

    private func saveRecentConversions(_ items: [RecentItem]) {
        guard let data = try? encoder.encode(items) else { return }
        try? data.write(to: recentConversionsURL, options: .atomic)
    }

    private func uniqueDestination(for url: URL) throws -> URL {
        let baseName = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension

        var candidate = exportsDirectory.appendingPathComponent("\(baseName).\(ext)")
        var index = 1
        while fileManager.fileExists(atPath: candidate.path) {
            candidate = exportsDirectory.appendingPathComponent("\(baseName)-\(index).\(ext)")
            index += 1
        }
        return candidate
    }

    private func createDirectoriesIfNeeded() {
        if !fileManager.fileExists(atPath: baseDirectory.path) {
            try? fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
        }
        if !fileManager.fileExists(atPath: exportsDirectory.path) {
            try? fileManager.createDirectory(at: exportsDirectory, withIntermediateDirectories: true)
        }
    }
}

extension Notification.Name {
    static let recentConversionsDidUpdate = Notification.Name("recentConversionsDidUpdate")
}

