import SwiftUI

/// Represents the app's appearance override options.
enum Appearance: String, CaseIterable, Identifiable {
    case light
    case dark
    case system

    var id: String { rawValue }

    /// Human-readable text used in settings pickers.
    var label: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }

    /// Maps the selection to an optional SwiftUI `ColorScheme` override.
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

/// Enumerates accent color choices exposed to the user.
enum AccentColorOption: String, CaseIterable, Identifiable {
    case blue
    case green
    case orange
    case red
    case purple


    var id: String { rawValue }

    /// Materializes the concrete `Color` for the option.
    var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .red: return .red
        case .purple: return .purple

        }
    }

    /// A softer variant of the accent color for backgrounds and gradients.
    var gradient: Color {
        color.opacity(0.25)
    }
}

