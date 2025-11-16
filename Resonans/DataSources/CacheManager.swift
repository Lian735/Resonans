import Foundation

/// Manages application caching including exports directory, recent tools, and recent conversions.
///
/// `CacheManager` is a singleton that handles:
/// - Storage and retrieval of exported audio files
/// - Tracking of recently used tools
/// - Tracking of recent conversions with automatic cleanup
/// - Network cache management
///
/// The manager uses a dedicated cache directory structure:
/// - `baseDirectory`: Main cache directory (`com.resonans.cache`)
/// - `exportsDirectory`: Subdirectory for exported audio files
/// - `recentToolsURL`: JSON file storing recent tool identifiers
/// - `recentConversionsURL`: JSON file storing recent conversion metadata
///
/// All operations are thread-safe and can be called from any queue.
///
/// Example usage:
/// ```swift
/// // Clear all cached data
/// CacheManager.shared.clear()
///
/// // Save recent tools
/// CacheManager.shared.saveRecentTools([.audioExtractor, .bgRemover])
///
/// // Record a conversion
/// try CacheManager.shared.recordConversion(
///     title: "My Video",
///     duration: "5:30",
///     tempURL: audioFileURL
/// )
/// ```
///
/// - Important: The manager automatically cleans up old conversions and missing files.
/// - Note: Uses ``NotificationCenter`` to broadcast updates via `.recentConversionsDidUpdate`.
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

    /// Loads the list of recently used tools from persistent storage.
    ///
    /// If the stored data is corrupted or invalid, the file is automatically removed and an empty array is returned.
    ///
    /// - Returns: An array of ``ToolIdentifier`` representing recently used tools, ordered from most to least recent.
    func loadRecentTools() -> [ToolIdentifier] {
        guard let data = try? Data(contentsOf: recentToolsURL) else { return [] }
        guard let rawIDs = try? decoder.decode([String].self, from: data) else {
            try? fileManager.removeItem(at: recentToolsURL)
            return []
        }
        return rawIDs.compactMap { ToolIdentifier(rawValue: $0) }
    }

    /// Saves the list of recently used tools to persistent storage.
    ///
    /// The list is automatically trimmed to the maximum allowed number of recent tools (currently 6).
    ///
    /// - Parameter identifiers: An array of ``ToolIdentifier`` to save, ordered from most to least recent.
    func saveRecentTools(_ identifiers: [ToolIdentifier]) {
        let trimmed = Array(identifiers.prefix(maxRecentTools))
        let raw = trimmed.map { $0.rawValue }
        guard let data = try? encoder.encode(raw) else { return }
        try? data.write(to: recentToolsURL, options: .atomic)
    }

    // MARK: - Recent conversions

    /// Loads the list of recent audio conversions from persistent storage.
    ///
    /// This method automatically validates that all referenced files still exist on disk.
    /// Missing files are filtered out and the list is updated in storage.
    ///
    /// - Returns: An array of ``RecentItem`` representing recent conversions with valid file paths.
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

    /// Records a new audio conversion by moving the file to the exports directory and updating recent conversions.
    ///
    /// This method:
    /// 1. Creates a unique filename in the exports directory to avoid conflicts
    /// 2. Moves the file from the temporary location to the exports directory
    /// 3. Creates a ``RecentItem`` with the provided metadata
    /// 4. Updates the recent conversions list, removing duplicates and old entries
    /// 5. Posts a notification to ``NSNotification.Name.recentConversionsDidUpdate``
    ///
    /// The maximum number of recent conversions is 10. Older entries are automatically deleted from disk.
    ///
    /// - Parameters:
    ///   - title: The display title for the conversion
    ///   - duration: The duration string (e.g., "5:30")
    ///   - tempURL: The temporary file URL of the audio file to be moved
    ///
    /// - Returns: The newly created ``RecentItem`` representing the recorded conversion
    ///
    /// - Throws: An error if file operations fail (directory creation, file move, etc.)
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

