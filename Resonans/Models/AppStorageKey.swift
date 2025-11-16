//
//  AppStorageKey.swift
//  Resonans
//
//  Created by Kevin Dallian on 03/11/25.
//

/// Centralized collection of `@AppStorage` keys used throughout the app.
struct AppStorageKey {
    // MARK: - Onboarding
    struct Onboarding {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let showGuidedTips = "showGuidedTips"
    }

    // MARK: - Settings
    /// Keys that persist user preferences in the settings tab.
    struct Settings {
        static let appearance = "appearance"
        static let accentColor = "accentColor"
        static let glassEffectActivated = "Glass Effect deactivated"
        static let interactiveGlassActivated = "Interactive Glass activated"
        static let reduceTransparencyActivated = "Reduce Transparency activated"
        static let hapticsEnabled = "hapticsEnabled"
        static let soundsEnabled = "soundsEnabled"
        static let experimentalEnabled = "experimentalEnabled"
    }
}
