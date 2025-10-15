import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: ContentViewModel
    
    @AppStorage("accentColor") private var accentRaw = AccentColorOption.purple.rawValue
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("showGuidedTips") private var showGuidedTips = true

    @Environment(\.colorScheme) private var colorScheme
    private var background: Color { AppStyle.background(for: colorScheme) }
    
    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }

    var body: some View {
        TabView {
            Tab(content: {
                homeTab
            }, label: {
                Label("Home", systemImage: "house")
            })
            Tab(content: {
                NavigationStack{
                    if #available(iOS 26, *){
                        ToolsView(accent: accent, primary: .primary)
                    }else{
                        ToolsView(accent: accent, primary: .primary)
                    }
                }
            }, label: {
                Label("Tools", systemImage: "wrench.and.screwdriver.fill")
            })
            Tab{
                SettingsView(scrollToTopTrigger: $viewModel.settingsScrollTrigger)
            }label: {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .onAppear {
            if !hasCompletedOnboarding {
                viewModel.showOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $viewModel.showOnboarding) {
            OnboardingFlowView(
                tools: viewModel.tools,
                accent: accent.color,
                primary: .primary,
                colorScheme: colorScheme
            ) { favorites, tips in
                viewModel.favoriteToolIds = favorites
                showGuidedTips = tips
                hasCompletedOnboarding = true
                viewModel.showOnboarding = false
                HapticsManager.shared.notify(.success)
            }
        }
        .tint(accent.color)
    }

    private var homeTab: some View {
        HomeDashboardView(
            tools: viewModel.tools,
            recentTools: viewModel.recentTools,
            scrollToTopTrigger: $viewModel.homeScrollTrigger,
            accent: accent,
            primary: .primary,
            colorScheme: colorScheme,
            onOpenTool: { viewModel.launchTool($0) },
            onShowTools: {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                    viewModel.selectedTab = .tools
                }
            }
        )
    }
}

#Preview { ContentView()
        .environmentObject(ContentViewModel())
}

