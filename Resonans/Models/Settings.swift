import SwiftUI

/// Represents the available appearance modes for the app.
///
/// `Appearance` allows users to choose between light mode, dark mode, or following the system setting.
///
/// Example usage:
/// ```swift
/// @AppStorage("appearance") private var appearanceRaw = Appearance.system.rawValue
/// private var appearance: Appearance { Appearance(rawValue: appearanceRaw) ?? .system }
///
/// // Apply to view
/// ContentView()
///     .preferredColorScheme(appearance.colorScheme)
/// ```
enum Appearance: String, CaseIterable, Identifiable {
    case light
    case dark
    case system

    var id: String { rawValue }

    var label: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

/// Represents the available accent color options for the app theme.
///
/// `AccentColorOption` provides a curated set of accent colors that can be applied throughout the app.
/// Each option includes both a solid color and a gradient variant for backgrounds.
///
/// Example usage:
/// ```swift
/// @AppStorage("accentColor") private var accentRaw = AccentColorOption.purple.rawValue
/// private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }
///
/// // Use the accent color
/// Button("Action") { }
///     .tint(accent.color)
///
/// // Use gradient for background
/// LinearGradient(colors: [accent.gradient, .clear], startPoint: .top, endPoint: .bottom)
/// ```
enum AccentColorOption: String, CaseIterable, Identifiable {
    case blue
    case green
    case orange
    case red
    case purple


    var id: String { rawValue }

    var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .red: return .red
        case .purple: return .purple

        }
    }

    var gradient: Color {
        color.opacity(0.25)
    }
}

