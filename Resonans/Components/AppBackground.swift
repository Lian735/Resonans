import SwiftUI

/// A reusable background view that provides a consistent app-wide appearance
/// by blending the selected accent color with the system background.
///
/// The gradient adapts to the active color scheme to keep contrast balanced
/// in both light and dark modes.
struct AppBackground: View {
    let accent: AccentColorOption

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var gradientColors: [Color] {
        let base = AppStyle.background(for: colorScheme)
        let accentColor = accent.color

        if colorScheme == .dark {
            return [
                accentColor.opacity(0.45),
                accentColor.opacity(0.15),
                base
            ]
        } else {
            return [
                accentColor.opacity(0.28),
                accentColor.opacity(0.1),
                base
            ]
        }
    }
}

extension View {
    /// Applies the standard Resonans background behind the current view hierarchy.
    func appBackground(accent: AccentColorOption) -> some View {
        background(AppBackground(accent: accent))
    }
}
