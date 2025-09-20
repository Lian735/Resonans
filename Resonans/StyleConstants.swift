import SwiftUI

/// Global layout constants that are shared across views.
enum AppStyle {
    /// Standard corner radius used throughout the app
    static let cornerRadius: CGFloat = 28
    /// Standard horizontal padding for boxed views
    static let horizontalPadding: CGFloat = 22
    /// Internal padding within boxed views
    static let innerPadding: CGFloat = 20
}

/// Surface styling related values.
enum AppSurface {
    /// Background fill opacity used for cards and grouped boxes.
    static let cardFillOpacity: Double = 0.09
    /// Border opacity for card outlines.
    static let cardStrokeOpacity: Double = 0.12
    /// Background opacity for small icon containers.
    static let iconFillOpacity: Double = 0.16
}

/// App-wide color helpers to keep color usage consistent.
enum AppColor {
    static func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .black : .white
    }

    static func primary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white : .black
    }

    static func elevatedBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(white: 0.1) : Color(white: 0.92)
    }
}

/// Discrete elevation levels for the app that describe the drop shadow to apply.
enum AppElevation {
    case text
    case low
    case medium
    case high

    var radius: CGFloat {
        switch self {
        case .text: return 4
        case .low: return 12
        case .medium: return 18
        case .high: return 26
        }
    }

    var yOffset: CGFloat {
        switch self {
        case .text: return 1
        case .low: return 6
        case .medium: return 10
        case .high: return 20
        }
    }

    var baseOpacity: Double {
        switch self {
        case .text: return 0.28
        case .low: return 0.35
        case .medium: return 0.45
        case .high: return 0.5
        }
    }

    var highlightOpacityLight: Double {
        switch self {
        case .text: return 0.18
        case .low: return 0.22
        case .medium: return 0.25
        case .high: return 0.28
        }
    }

    var highlightOpacityDark: Double {
        switch self {
        case .text: return 0.08
        case .low: return 0.08
        case .medium: return 0.1
        case .high: return 0.12
        }
    }
}

private struct AppShadowModifier: ViewModifier {
    let elevation: AppElevation
    let colorScheme: ColorScheme

    func body(content: Content) -> some View {
        content
            .shadow(
                color: Color.black.opacity(elevation.baseOpacity),
                radius: elevation.radius,
                x: 0,
                y: elevation.yOffset
            )
            .shadow(
                color: Color.white.opacity(
                    colorScheme == .dark ? elevation.highlightOpacityDark : elevation.highlightOpacityLight
                ),
                radius: 1,
                x: 0,
                y: 1
            )
    }
}

private struct AppCardBackgroundModifier: ViewModifier {
    let primary: Color
    let colorScheme: ColorScheme
    let cornerRadius: CGFloat
    let elevation: AppElevation

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(primary.opacity(AppSurface.cardFillOpacity))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(primary.opacity(AppSurface.cardStrokeOpacity), lineWidth: 1)
                    )
            )
            .appShadow(elevation, colorScheme: colorScheme)
    }
}

private struct AppIconBackgroundModifier: ViewModifier {
    let primary: Color
    let colorScheme: ColorScheme
    let cornerRadius: CGFloat
    let elevation: AppElevation

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(primary.opacity(AppSurface.iconFillOpacity))
            )
            .appShadow(elevation, colorScheme: colorScheme)
    }
}

extension View {
    /// Applies a consistent app shadow for the provided elevation level.
    func appShadow(_ elevation: AppElevation = .medium, colorScheme: ColorScheme) -> some View {
        modifier(AppShadowModifier(elevation: elevation, colorScheme: colorScheme))
    }

    /// Applies the common card styling (background, border, shadow).
    func appCardBackground(
        primary: Color,
        colorScheme: ColorScheme,
        cornerRadius: CGFloat = AppStyle.cornerRadius,
        elevation: AppElevation = .medium
    ) -> some View {
        modifier(
            AppCardBackgroundModifier(
                primary: primary,
                colorScheme: colorScheme,
                cornerRadius: cornerRadius,
                elevation: elevation
            )
        )
    }

    /// Applies the styling used for small icon containers.
    func appIconBackground(
        primary: Color,
        colorScheme: ColorScheme,
        cornerRadius: CGFloat = 14,
        elevation: AppElevation = .low
    ) -> some View {
        modifier(
            AppIconBackgroundModifier(
                primary: primary,
                colorScheme: colorScheme,
                cornerRadius: cornerRadius,
                elevation: elevation
            )
        )
    }
}
