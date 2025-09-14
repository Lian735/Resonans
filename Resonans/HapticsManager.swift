import UIKit

final class HapticsManager {
    static let shared = HapticsManager()
    private init() {}

    /// Triggers a haptic feedback if the user enabled vibrations in settings.
    /// - Parameter style: The impact style to use. Defaults to `.light`.
    func pulse(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let defaults = UserDefaults.standard
        let enabled = defaults.object(forKey: "hapticsEnabled") == nil ? true : defaults.bool(forKey: "hapticsEnabled")
        guard enabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

