//
//  CostumButtonStyle.swift
//  Resonans
//
//  Created by Samuel Meincke on 25.11.25.
//
import SwiftUI

/// A reusable SwiftUI `ButtonStyle` that renders buttons with the app’s default “Resonans” appearance.
///
/// This style supports a glass effect with a colored capsule background and a subtle stroke,
/// respecting a user preference to enable or disable the glass effect. It also allows per-instance
/// disabling of the glass effect regardless of user settings.
///
/// Behavior:
/// - When the glass effect is enabled (via AppStorage) and not explicitly disabled for this instance,
///   the button’s label is styled with:
///   - Foreground color using the system label color
///   - Vertical and horizontal padding
///   - A capsule-shaped background filled with the selected accent color at 50% opacity
///   - A thin stroke around the capsule using the same accent color
///   - A `.glassEffect(.regular.interactive())` visual effect overlay
/// - When the glass effect is disabled (either globally or for this instance), the label is returned unmodified.
///
/// AppStorage keys:
/// - `AppStorageKey.Settings.glassEffectActivated`: A Boolean indicating whether the glass effect is globally enabled.
/// - `"accentColor"`: A `String`-backed raw value corresponding to `AccentColorOption`, used to determine the accent color.
///
/// Dependencies:
/// - `AccentColorOption`: An enum providing a `rawValue` initializer and a `color` property (used to construct `Color(accent.color)`).
/// - `AppStorageKey.Settings.glassEffectActivated`: A namespaced key for the glass effect toggle.
/// - `.glassEffect` modifier: Requires platforms where this SwiftUI modifier is available (e.g., visionOS).
///
/// Initialization:
/// - `init(disableGlassEffect:)`: Pass `true` to force-disable the glass effect for this instance, regardless of the global setting.
///
/// Example usage:
/// ```swift
/// Button("Continue") { /* action */ }
///     .buttonStyle(ResonansDefaultButtonStyle())
///
/// Button("Plain") { /* action */ }
///     .buttonStyle(ResonansDefaultButtonStyle(disableGlassEffect: true))
/// ```
///
struct ResonansDefaultButtonStyle: ButtonStyle{
    @AppStorage(AppStorageKey.Settings.glassEffectActivated) private var glassEffectActivated: Bool = true
    
    @AppStorage("accentColor") private var accentRaw: String = AccentColorOption.purple.rawValue
    
    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }
    
    private let disableGlassEffect: Bool
    
    init(disableGlassEffect disabled: Bool = false){
        disableGlassEffect = disabled
    }
    
    func makeBody(configuration config : Configuration) -> some View {
        if glassEffectActivated && !disableGlassEffect{
            config.label
                .foregroundStyle(Color(.label))
                .padding(.vertical, 7)
                .padding(.horizontal, 10)
                .background {
                    Capsule()
                        .foregroundStyle(Color(accent.color))
                        .opacity(0.5)
                        .overlay(
                            Capsule()
                                .stroke(Color(accent.color), lineWidth: 0.75)
                        )
                }
                .glassEffect(.regular.interactive())
        }else{
            config.label
        }
    }
}
