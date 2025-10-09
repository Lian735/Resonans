//
//  ShadowConfig.swift
//  Resonans
//
import SwiftUI

/// Configuration for `.shadow(_:)`.
///
/// Use ``DefaultShadowConfiguration`` for default presets, or build your own by
/// initializing ``ShadowConfiguration`` directly.
///
/// - Parameters:
///   - color: The shadow color (set opacity on the color as needed).
///   - radius: The blur radius of the shadow.
///   - offset: The shadow offset. Use `width` for horizontal and `height` for vertical displacement.
struct ShadowConfiguration: Equatable{
    var color: Color = Color(.sRGBLinear, white: 0, opacity: 0.33)
    
    var radius: CGFloat
    
    var offset: CGSize = .zero
    
    /// Returns the default small shadow configuration for the given color scheme.
    ///
    /// This preset is suitable for subtle depth, like small controls or compact elements.
    ///
    /// - Parameter colorScheme: The current color scheme (e.g., `.light` or `.dark`).
    /// - Returns: A ``ShadowConfiguration``
    static func smallConfiguration(for colorScheme: ColorScheme) -> ShadowConfiguration {
        DefaultShadowConfiguration.small.configuration(for: colorScheme)
    }
    
    /// Returns the default medium shadow configuration for the given color scheme.
    ///
    /// Use this for general-purpose elevation where a more noticeable shadow is needed.
    ///
    /// - Parameter colorScheme: The current color scheme (e.g., `.light` or `.dark`).
    /// - Returns: A ``ShadowConfiguration``
    static func mediumConfiguration(for colorScheme: ColorScheme) -> ShadowConfiguration {
        DefaultShadowConfiguration.medium.configuration(for: colorScheme)
    }
    
    /// Returns the default large shadow configuration for the given color scheme.
    ///
    /// Best for prominent surfaces or modals that require strong separation from the background.
    ///
    /// - Parameter colorScheme: The current color scheme (e.g., `.light` or `.dark`).
    /// - Returns: A ``ShadowConfiguration`` tuned for large usage.
    static func largeConfiguration(for colorScheme: ColorScheme) -> ShadowConfiguration {
        DefaultShadowConfiguration.large.configuration(for: colorScheme)
    }
    
    /// Returns the default text shadow configuration for the given color scheme.
    ///
    /// Intended for improving text legibility and subtle emphasis without heavy blur.
    ///
    /// - Parameter colorScheme: The current color scheme (e.g., `.light` or `.dark`).
    /// - Returns: A ``ShadowConfiguration`` tuned for text.
    static func textConfiguration(for colorScheme: ColorScheme) -> ShadowConfiguration {
        DefaultShadowConfiguration.text.configuration(for: colorScheme)
    }
}

