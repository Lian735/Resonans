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
        PreConfiguration.small.configuration(for: colorScheme)
    }
    
    /// Returns the default medium shadow configuration for the given color scheme.
    ///
    /// Use this for general-purpose elevation where a more noticeable shadow is needed.
    ///
    /// - Parameter colorScheme: The current color scheme (e.g., `.light` or `.dark`).
    /// - Returns: A ``ShadowConfiguration``
    static func mediumConfiguration(for colorScheme: ColorScheme) -> ShadowConfiguration {
        PreConfiguration.medium.configuration(for: colorScheme)
    }
    
    /// Returns the default large shadow configuration for the given color scheme.
    ///
    /// Best for prominent surfaces or modals that require strong separation from the background.
    ///
    /// - Parameter colorScheme: The current color scheme (e.g., `.light` or `.dark`).
    /// - Returns: A ``ShadowConfiguration`` tuned for large usage.
    static func largeConfiguration(for colorScheme: ColorScheme) -> ShadowConfiguration {
        PreConfiguration.large.configuration(for: colorScheme)
    }
    
    /// Returns the default text shadow configuration for the given color scheme.
    ///
    /// Intended for improving text legibility and subtle emphasis without heavy blur.
    ///
    /// - Parameter colorScheme: The current color scheme (e.g., `.light` or `.dark`).
    /// - Returns: A ``ShadowConfiguration`` tuned for text.
    static func textConfiguration(for colorScheme: ColorScheme) -> ShadowConfiguration {
        PreConfiguration.text.configuration(for: colorScheme)
    }
    
    /// A set of predefined shadow styles used throughout the app.
    /// 
    /// Use `DefaultShadowConfiguration` to retrieve a standardized `ShadowConfiguration`
    /// appropriate for a given UI context (e.g., large cards, medium elements, small controls, or text).
    /// This helps maintain consistent elevation, depth, and readability across light and dark modes.
    ///
    /// Usage:
    /// - Choose a case that best represents the component size or purpose.
    /// - Call `configuration(with:)` to obtain a `ShadowConfiguration` tuned for the current `ColorScheme`.
    ///
    /// Example:
    /// ```swift
    /// let shadow = DefaultShadowConfiguration.large.configuration(with: colorScheme)
    /// ```
    ///
    /// - Note: Currently, the shadow color is the same in both light and dark modes.
    ///   Adjustments can be made inside `configuration(with:)` if different colors are desired.
    //TODO: Make this enum private
    enum PreConfiguration {
        /// A pronounced shadow suitable for prominent surfaces like large cards or modals.
        ///
        /// - Appearance:
        ///   - Radius: 26
        ///   - Offset: (0, 20)
        ///   - Color: Black (light and dark mode)
        case large
        
        /// A balanced shadow for medium-sized components such as tiles or grouped content.
        ///
        /// - Appearance:
        ///   - Radius: 22
        ///   - Offset: (0, 14)
        ///   - Color: Black (light and dark mode)
        case medium
        
        /// A subtle shadow for compact UI elements like buttons or small containers.
        ///
        /// - Appearance:
        ///   - Radius: 18
        ///   - Offset: (0, 10)
        ///   - Color: Black (light and dark mode)
        case small
        
        /// A minimal shadow intended for text to improve legibility against varied backgrounds.
        ///
        /// - Appearance:
        ///   - Radius: 4
        ///   - Offset: (0, 1)
        ///   - Color: Black (light and dark mode)
        case text
        
        /// Returns a concrete `ShadowConfiguration` for the selected preset, adapted to the provided color scheme.
        ///
        /// - Parameter colorScheme: The current interface color scheme (light or dark).
        /// - Returns: A `ShadowConfiguration` containing color, radius, and offset values for the preset.
        ///
        /// - Important: If you need different shadow colors for light and dark modes,
        ///   modify the color selection logic here or build a costum ``ShadowConfiguration``.
        func configuration(for colorScheme: ColorScheme) -> ShadowConfiguration {
            switch self {
            case .large:
                return ShadowConfiguration(color: colorScheme == .light ? .black : .black, radius: 26, offset: CGSize(width: 0, height: 20))
            case .medium:
                return ShadowConfiguration(color: colorScheme == .light ? .black : .black, radius: 22, offset: CGSize(width: 0, height: 14))
            case .small:
                return ShadowConfiguration(color: colorScheme == .light ? Color(.sRGBLinear, white: 0.0, opacity: 0.5) : .black, radius: 8, offset: CGSize(width: 0, height: 0))
            case .text:
                return ShadowConfiguration(color: colorScheme == .light ? Color(.sRGBLinear, white: 0.0, opacity: 0.5) : .black, radius: 4, offset: CGSize(width: 0, height: 1))
            }
        }
    }
    
    //TODO: Make this typealias deprecated and delete this
    typealias Configuration = PreConfiguration
}

