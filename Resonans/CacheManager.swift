import Foundation

final class CacheManager {
    static let shared = CacheManager()
    private init() {}

    /// Clears any cached network responses.
    func clear() {
        URLCache.shared.removeAllCachedResponses()
    }
}
