import SwiftUI

struct AppTheme {
    let accent: AccentColorOption
    let colorScheme: ColorScheme

    var accentColor: Color { accent.color }

    var background: Color {
        if colorScheme == .dark {
            return Color(.systemBackground)
        } else {
            return Color(.systemGroupedBackground)
        }
    }

    var foreground: Color {
        colorScheme == .dark ? .white : .black
    }

    var secondary: Color {
        foreground.opacity(0.7)
    }

    var tertiary: Color {
        foreground.opacity(0.5)
    }

    var surface: Color {
        if colorScheme == .dark {
            return Color.white.opacity(0.08)
        } else {
            return Color.white
        }
    }

    var subtleSurface: Color {
        if colorScheme == .dark {
            return Color.white.opacity(0.05)
        } else {
            return Color.black.opacity(0.03)
        }
    }

    var border: Color {
        if colorScheme == .dark {
            return Color.white.opacity(0.15)
        } else {
            return Color.black.opacity(0.08)
        }
    }

    var separator: Color {
        if colorScheme == .dark {
            return Color.white.opacity(0.12)
        } else {
            return Color.black.opacity(0.12)
        }
    }

    var shadow: Color {
        if colorScheme == .dark {
            return Color.black.opacity(0.45)
        } else {
            return Color.black.opacity(0.08)
        }
    }

    var buttonBackground: Color {
        accentColor.opacity(colorScheme == .dark ? 0.3 : 0.15)
    }
}

struct SurfaceCard<Content: View>: View {
    let theme: AppTheme
    let padding: CGFloat
    let content: Content

    init(theme: AppTheme, padding: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.theme = theme
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(theme.border, lineWidth: 1)
                    )
            )
            .shadow(color: theme.shadow, radius: 12, x: 0, y: 6)
    }
}

extension View {
    func themedBackground(_ theme: AppTheme) -> some View {
        background(theme.background.ignoresSafeArea())
    }
}
