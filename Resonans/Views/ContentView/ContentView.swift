import SwiftUI

/// The root view of the app containing the main tab bar navigation.
///
/// `ContentView` manages:
/// - Tab-based navigation between Home, Tools, and Settings
/// - Onboarding flow presentation for first-time users
/// - Theme application (accent color and appearance)
///
/// The view consists of three tabs:
/// - **Home**: ``HomeDashboardView`` with favorites and recent tools
/// - **Tools**: ``ToolsView`` with searchable tool catalog
/// - **Settings**: ``SettingsView`` for app configuration
///
/// On first launch (when `hasCompletedOnboarding` is false), the onboarding flow is automatically presented.
///
/// Example usage:
/// ```swift
/// ContentView()
///     .environmentObject(ContentViewModel())
/// ```
///
/// - Important: Requires a ``ContentViewModel`` to be provided via `@EnvironmentObject`.
/// - Note: Uses `@AppStorage` to persist user preferences for accent color, appearance, and onboarding status.
struct ContentView: View {
    @EnvironmentObject private var viewModel: ContentViewModel
    
    @AppStorage(AppStorageKey.Settings.accentColor) private var accentRaw = AccentColorOption.purple.rawValue
    @AppStorage(AppStorageKey.Onboarding.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @AppStorage(AppStorageKey.Onboarding.showGuidedTips) private var showGuidedTips = true

    @Environment(\.colorScheme) private var colorScheme
    
    private var background: Color { AppStyle.background(for: colorScheme) }
    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            Tab(value: .home, content: {
                HomeDashboardView(accent: accent, primary: .primary)
                    .environmentObject(viewModel)
            }, label: {
                Label {
                    Text("Home")
                } icon: {
                    Image("resonanslogo.SFSymbol")
                }
            })
            Tab(value: .tools, content: {
                ToolsView(accent: accent, primary: .primary)
                    .environmentObject(viewModel)
            }, label: {
                Label("Tools", systemImage: "rectangle.stack")
            })
            Tab(value: .settings){
                SettingsView()
            }label: {
                Label("Settings", systemImage: "gearshape")
            }
        }
        .labelStyle(.iconOnly)
        .onAppear {
            if !hasCompletedOnboarding {
                viewModel.showOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $viewModel.showOnboarding) {
            OnboardingFlowView(
                accent: accent.color,
                primary: .primary
            ) { favorites, tips in
                viewModel.favoriteToolIds = favorites
                showGuidedTips = tips
                hasCompletedOnboarding = true
                HapticsManager.shared.notify(.success)
            }
        }
        .tint(accent.color)
    }
}

#Preview { ContentView()
        .environmentObject(ContentViewModel())
}

