import UIKit

/// Manages haptic feedback throughout the app, respecting user preferences.
///
/// `HapticsManager` is a singleton that provides a centralized way to trigger haptic feedback.
/// All haptic methods check the user's "hapticsEnabled" preference before executing.
///
/// The manager provides three types of haptic feedback:
/// - **Impact**: Physical collision or button press (light, medium, heavy, soft, rigid)
/// - **Selection**: Indicates a change in selection
/// - **Notification**: Success, warning, or error states
///
/// Example usage:
/// ```swift
/// // Trigger a light impact
/// HapticsManager.shared.pulse()
///
/// // Trigger a heavier impact
/// HapticsManager.shared.pulse(.heavy)
///
/// // Trigger selection feedback
/// HapticsManager.shared.selection()
///
/// // Trigger success notification
/// HapticsManager.shared.notify(.success)
/// ```
///
/// - Note: All methods are safe to call from any thread. If haptics are disabled in settings, methods return immediately without effect.
/// - Important: The user preference is stored in `UserDefaults` with key "hapticsEnabled" (defaults to `true`).
final class HapticsManager {
    static let shared = HapticsManager()
    private init() {}

    /// Triggers a haptic feedback if the user enabled vibrations in settings.
    /// - Parameter style: The impact style to use. Defaults to `.light`.
    func pulse(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .soft) {
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

