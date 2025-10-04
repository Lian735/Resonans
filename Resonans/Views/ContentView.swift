import SwiftUI

struct ContentView: View {
    private enum Tab: Hashable {
        case home
        case tools
        case settings
    }

    @State private var selectedTab: Tab = .home
    @State private var presentedTool: ToolItem?

    private let tools = ToolItem.all
    @State private var favoriteToolIDs: Set<ToolItem.Identifier> = [.audioExtractor]
    @State private var recentToolIDs: [ToolItem.Identifier] = CacheManager.shared.loadRecentTools()

    @AppStorage("accentColor") private var accentRaw = AccentColorOption.purple.rawValue
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("showGuidedTips") private var showGuidedTips = true
    @State private var showOnboarding = false

    @Environment(\.colorScheme) private var colorScheme

    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }
    private var theme: AppTheme { AppTheme(accent: accent, colorScheme: colorScheme) }

    private var recentTools: [ToolItem] {
        recentToolIDs.compactMap { id in tools.first(where: { $0.id == id }) }
    }

    private var favoriteTools: [ToolItem] {
        tools.filter { favoriteToolIDs.contains($0.id) }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeDashboardView(
                    theme: theme,
                    favoriteTools: favoriteTools,
                    recentTools: recentTools,
                    allTools: tools,
                    onSelectTool: open,
                    onShowAllTools: {
                        HapticsManager.shared.selection()
                        selectedTab = .tools
                    }
                )
                .navigationTitle("Home")
                .navigationBarTitleDisplayMode(.large)
                .background(theme.background)
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(Tab.home)

            NavigationStack {
                ToolsView(
                    theme: theme,
                    tools: tools,
                    favorites: $favoriteToolIDs,
                    onSelectTool: open
                )
                .navigationTitle("Tools")
                .navigationBarTitleDisplayMode(.large)
                .background(theme.background)
            }
            .tabItem { Label("Tools", systemImage: "wrench.and.screwdriver.fill") }
            .tag(Tab.tools)

            NavigationStack {
                SettingsView(theme: theme) {
                    showOnboarding = true
                }
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.large)
                .background(theme.background)
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            .tag(Tab.settings)
        }
        .tint(theme.accentColor)
        .background(theme.background.ignoresSafeArea())
        .sheet(item: $presentedTool) { tool in
            NavigationStack {
                tool.destination { presentedTool = nil }
                    .navigationTitle(tool.title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { presentedTool = nil }
                        }
                    }
            }
            .tint(theme.accentColor)
        }
        .onAppear {
            if !hasCompletedOnboarding {
                showOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingFlowView(
                tools: tools,
                accent: theme.accentColor,
                primary: theme.foreground,
                colorScheme: colorScheme
            ) { favorites, tips in
                favoriteToolIDs = favorites
                showGuidedTips = tips
                hasCompletedOnboarding = true
                showOnboarding = false
                HapticsManager.shared.notify(.success)
            }
        }
    }

    private func open(_ tool: ToolItem) {
        updateRecents(with: tool.id)
        HapticsManager.shared.selection()
        presentedTool = tool
    }

    private func updateRecents(with identifier: ToolItem.Identifier) {
        recentToolIDs.removeAll(where: { $0 == identifier })
        recentToolIDs.insert(identifier, at: 0)
        if recentToolIDs.count > 6 {
            recentToolIDs = Array(recentToolIDs.prefix(6))
        }
        CacheManager.shared.saveRecentTools(recentToolIDs)
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.light)
}
