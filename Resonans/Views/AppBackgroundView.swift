import SwiftUI

struct AppBackgroundView: View {
    let accent: AccentColorOption
    @Environment(\.colorScheme) private var colorScheme

    private var gradient: LinearGradient {
        let baseColor = accent.color
        let topOpacity = colorScheme == .dark ? 0.55 : 0.35
        let midOpacity = colorScheme == .dark ? 0.25 : 0.15
        return LinearGradient(
            colors: [
                baseColor.opacity(topOpacity),
                baseColor.opacity(midOpacity),
                AppStyle.background(for: colorScheme)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        AppStyle.background(for: colorScheme)
            .overlay(gradient)
            .overlay(noiseOverlay.opacity(colorScheme == .dark ? 0.08 : 0.04))
            .ignoresSafeArea()
    }

    private var noiseOverlay: some View {
        RadialGradient(
            gradient: Gradient(colors: [
                Color.white.opacity(colorScheme == .dark ? 0.04 : 0.08),
                .clear
            ]),
            center: .top,
            startRadius: 0,
            endRadius: 600
        )
    }
}

extension View {
    func appBackground(accent: AccentColorOption) -> some View {
        background(AppBackgroundView(accent: accent))
    }
}
