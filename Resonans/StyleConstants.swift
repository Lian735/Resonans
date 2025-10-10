import SwiftUI

enum AppStyle {
    /// Standard corner radius used throughout the app
    static let cornerRadius: CGFloat = 28
    /// Compact corner radius for smaller cards and rows
    static let compactCornerRadius: CGFloat = 22
    /// Corner radius for icons and thumbnails
    static let iconCornerRadius: CGFloat = 14

    /// Standard horizontal padding for boxed views
    static let horizontalPadding: CGFloat = 22
    /// Internal padding within boxed views
    static let innerPadding: CGFloat = 20

    /// Default opacity values for card backgrounds and strokes
    static let cardFillOpacity: Double = 0.09
    static let compactCardFillOpacity: Double = 0.12
    static let subtleCardFillOpacity: Double = 0.07
    static let iconFillOpacity: Double = 0.14
    static let strokeOpacity: Double = 0.10
    static let iconStrokeOpacity: Double = 0.12
    static let textShadowOpacity: Double = 0.8

    enum ShadowLevel {
        case small
        case medium
        case large
        case text
    }

    struct ShadowConfiguration {
        let radius: CGFloat
        let yOffset: CGFloat
        let opacity: Double
        let includesHighlight: Bool
    }

    @available(*, deprecated, message: "Use DefaultShadowConfiguration instead.")
    static func shadowConfiguration(for level: ShadowLevel) -> ShadowConfiguration {
        switch level {
        case .large:
            return .init(radius: 26, yOffset: 20, opacity: 0.6, includesHighlight: true)
        case .medium:
            return .init(radius: 22, yOffset: 14, opacity: 0.55, includesHighlight: true)
        case .small:
            return .init(radius: 18, yOffset: 10, opacity: 0.5, includesHighlight: true)
        case .text:
            return .init(radius: 4, yOffset: 1, opacity: textShadowOpacity, includesHighlight: false)
        }
    }

    static func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .black : .white
    }

    @available(*, deprecated, message: "Use colorScheme-Environment directly")
    static func primary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white : .black
    }

    static func shadowColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .black : .black
    }

    static func highlightShadowColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.25)
    }
}

/// A reusable SwiftUI `ViewModifier` that applies a consistent, theme-aware shadow style across the app.
/// 
/// This modifier:
/// - Looks up a predefined shadow configuration based on the provided `AppStyle.ShadowLevel`.
/// - Applies a primary drop shadow using the current `ColorScheme` (dark or light) to determine color and intensity.
/// - Optionally overlays a subtle highlight shadow to enhance elevation and depth, depending on the configuration.
/// - Supports overriding the default shadow opacity at call site.
/// 
/// Parameters:
/// - colorScheme: The current `ColorScheme` (e.g., `.light`, `.dark`) used to select appropriate shadow colors.
/// - level: The desired shadow intensity and geometry, defined by `AppStyle.ShadowLevel` (`.small`, `.medium`, `.large`, `.text`).
/// - overrideOpacity: An optional value to override the default opacity from the shadow configuration.
/// 
/// Behavior:
/// - Retrieves a `ShadowConfiguration` from `AppStyle.shadowConfiguration(for:)`.
/// - Computes the effective opacity using `overrideOpacity` if provided; otherwise uses the configuration’s default.
/// - Applies the main shadow with the configured radius and vertical offset.
/// - Conditionally applies a highlight shadow (small, light-colored accent) when `includesHighlight` is true in the configuration.
/// 
/// Use cases:
/// - Apply consistent elevation to cards, buttons, and other components using `.appShadow(colorScheme:level:opacity:)`.
/// - Use `.text` level for subtle text shadows to improve readability on varying backgrounds.
/// 
/// Notes:
/// - This modifier is intended to be used via the `View.appShadow(...)` convenience extension.
/// - Shadow colors and highlight behavior are centralized in `AppStyle` for consistency and easy theming.
@available(*, deprecated, message: "Use .shadow(_:) instead.")
private struct AppShadowModifier: ViewModifier {
    let colorScheme: ColorScheme
    let level: AppStyle.ShadowLevel
    let overrideOpacity: Double?

    func body(content: Content) -> some View {
        let configuration = AppStyle.shadowConfiguration(for: level)
        let mainOpacity = overrideOpacity ?? configuration.opacity

        return content
            .shadow(
                color: AppStyle.shadowColor(for: colorScheme).opacity(mainOpacity),
                radius: configuration.radius,
                x: 0,
                y: configuration.yOffset
            )
            .modifier(
                ConditionalShadowModifier(
                    enabled: configuration.includesHighlight,
                    color: AppStyle.highlightShadowColor(for: colorScheme),
                    radius: 1,
                    x: 0,
                    y: 1
                )
            )
    }
}

@available(*, deprecated, message: "Use .shadow(_:)-Architecture instead.")
private struct ConditionalShadowModifier: ViewModifier {
    let enabled: Bool
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    func body(content: Content) -> some View {
        if enabled {
            content.shadow(color: color, radius: radius, x: x, y: y)
        } else {
            content
        }
    }
}

@available(*, deprecated, message: "Use AppCard(content:) instead")
private struct AppCardStyleModifier: ViewModifier {
    let primary: Color
    let colorScheme: ColorScheme
    let cornerRadius: CGFloat
    let fillOpacity: Double
    let strokeOpacity: Double
    let shadowLevel: ShadowConfiguration.Configuration
    let shadowOpacity: Double?

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(primary.opacity(fillOpacity))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(primary.opacity(strokeOpacity), lineWidth: 1)
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(shadowLevel.configuration(for: colorScheme))
    }
}

extension View {
    @available(*, deprecated, message: "Use AppCard(content:) instead")
    func appCardStyle(
        primary: Color,
        colorScheme: ColorScheme,
        cornerRadius: CGFloat = AppStyle.cornerRadius,
        fillOpacity: Double = AppStyle.cardFillOpacity,
        strokeOpacity: Double = AppStyle.strokeOpacity,
        shadowLevel: ShadowConfiguration.Configuration = .medium,
        shadowOpacity: Double? = nil
    ) -> some View {
        modifier(
            AppCardStyleModifier(
                primary: primary,
                colorScheme: colorScheme,
                cornerRadius: cornerRadius,
                fillOpacity: fillOpacity,
                strokeOpacity: strokeOpacity,
                shadowLevel: shadowLevel,
                shadowOpacity: shadowOpacity
            )
        )
    }
}
