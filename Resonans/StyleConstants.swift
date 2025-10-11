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
