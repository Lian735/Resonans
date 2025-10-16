//
//  Font.swift
//  Resonans
//
//  Created by Kevin Dallian on 15/10/25.
//

import Foundation
import SwiftUI

// MARK: - Typography System
/// `Typography` defines a reusable, centralized set of text styles
/// used throughout the app. Each case represents a typographic role
/// (e.g., display, title, body, caption) that encodes both size and weight.
///
/// ## Core Concept
/// Instead of scattering `.font(.system(size:weight:))` across views,
/// this enum provides a single source of truth for consistent typography.
/// Designers and developers can update text hierarchy in one place.
///
/// ## Implementation
/// Apply these styles in SwiftUI using the custom `typography(_:)`
/// view modifier. Example:
///
/// ```swift
/// Text("Welcome Back")
///     .typography(.titleLarge)
/// ```
///
/// You can also specify a custom text color:
///
/// ```swift
/// Text("Tap to continue")
///     .typography(.caption, color: .secondary)
/// ```
enum Typography {
    /// Display Styles
    case displayLarge
    case displayMedium
    case displaySmall
    
    /// Title Styles
    case titleLarge
    case titleMedium
    case titleSmall
    
    /// Text Styles
    case body
    case callout
    case caption
    
    /// Emphasis Variants
    case bodyBold
    case captionBold
    
    /// Custom cases
    /// - Parameters:
    ///   - size: The custom font size in points.
    ///   - weight: The desired font weight (e.g., `.regular`, `.bold`).
    case custom(size: CGFloat, weight: Font.Weight)
    
    // MARK: - Font Size
    /// Defines the base point size for each text style.
    /// Sizes are inspired by Apple’s Human Interface Guidelines (HIG).
    var size: CGFloat {
        switch self {
        case .displayLarge: 40
        case .displayMedium: 34
        case .displaySmall: 28
        case .titleLarge: 22
        case .titleMedium: 20
        case .titleSmall: 17
        case .body, .bodyBold: 17
        case .callout: 16
        case .caption, .captionBold: 13
        case .custom(let size, _): size
        }
    }
    
    // MARK: - Font Weight
    /// Each typography case maps to an appropriate font weight
    /// to visually communicate hierarchy and emphasis.
    var weight: Font.Weight {
        switch self {
        case .displayLarge, .displayMedium, .displaySmall:
            return .bold
        case .titleLarge, .titleMedium:
            return .semibold
        case .titleSmall:
            return .medium
        case .body:
            return .regular
        case .bodyBold:
            return .semibold
        case .callout:
            return .regular
        case .caption:
            return .regular
        case .captionBold:
            return .semibold
        case .custom(_, let weight):
            return weight
        }
    }
    
    // MARK: - Computed Font
    /// Combines size, weight, and design into a reusable `Font` instance.
    var font: Font {
        .system(size: size, weight: weight, design: .default)
    }
}

// MARK: - Typography Modifier
/// `TypographyViewModifier` applies a predefined `Typography` style
/// and color to any SwiftUI `View` (typically `Text`).
///
/// This modifier encapsulates all font styling logic,
/// keeping the main view code declarative and clean.
struct TypographyViewModifier: ViewModifier {
    let typography: Typography
    let color: Color
    let design: Font.Design
    
    init(typography: Typography, color: Color, design: Font.Design) {
        self.typography = typography
        self.color = color
        self.design = design
    }
    
    func body(content: Content) -> some View {
        content
            .font(typography.font)
            .foregroundStyle(color)
    }
}

// MARK: - View Extension
/// A convenience extension to apply `Typography` styles succinctly.
///
/// ### Example
/// ```swift
/// Text("Settings")
///     .typography(.titleMedium)
///
/// Text("Version 1.0.0")
///     .typography(.caption, color: .secondary)
/// ```
extension View {
    func typography(_ typography: Typography, color: Color = .primary, design: Font.Design = .default) -> some View {
        self.modifier(TypographyViewModifier(typography: typography, color: color, design: design))
    }
}
