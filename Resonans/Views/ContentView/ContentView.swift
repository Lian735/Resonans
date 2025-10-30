import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: ContentViewModel
    
    @AppStorage("accentColor") private var accentRaw = AccentColorOption.purple.rawValue
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("showGuidedTips") private var showGuidedTips = true

    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }

    @State private var homePath = NavigationPath()
    @State private var toolsPath = NavigationPath()

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            NavigationStack(path: $homePath) {
                HomeDashboardView()
                    .environmentObject(viewModel)
            }
            .navigationDestination(for: ToolIdentifier.self) { identifier in
                ToolDestinationView(toolIdentifier: identifier)
                    .environmentObject(viewModel)
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(TabSelection.home)

            NavigationStack(path: $toolsPath) {
                ToolsView()
                    .environmentObject(viewModel)
            }
            .navigationDestination(for: ToolIdentifier.self) { identifier in
                ToolDestinationView(toolIdentifier: identifier)
                    .environmentObject(viewModel)
            }
            .tabItem {
                Label("Tools", systemImage: "wrench.and.screwdriver")
            }
            .tag(TabSelection.tools)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(TabSelection.settings)
        }
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

