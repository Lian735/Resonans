import UIKit

final class HapticsManager {
    static let shared = HapticsManager()
    private init() {}

    /// Triggers a haptic feedback if the user enabled vibrations in settings.
    /// - Parameter style: The impact style to use. Defaults to `.light`.
    func pulse(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard hapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Provides a subtle selection change feedback.
    func selection() {
        guard hapticsEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    /// Provides a notification style feedback (success, warning, error).
    /// - Parameter type: The notification feedback type.
    func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard hapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    private var hapticsEnabled: Bool {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: "hapticsEnabled") == nil ? true : defaults.bool(forKey: "hapticsEnabled")
    }
}

