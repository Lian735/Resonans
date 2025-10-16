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
        TabView(selection: $viewModel.selectedTab) {
            Tab(value: .home, content: {
                HomeDashboardView(accent: accent, primary: .primary)
                    .environmentObject(viewModel)
            }, label: {
                Label("Home", systemImage: "house")
            })
            Tab(value: .tools, content: {
                NavigationStack{
                    if #available(iOS 26, *){
                        GlassEffectContainer{
                            ToolsView(accent: accent, primary: .primary)                    .environmentObject(viewModel)
                        }
                    }else{
                        ToolsView(accent: accent, primary: .primary)
                            .environmentObject(viewModel)
                    }
                }
            }, label: {
                Label("Tools", systemImage: "wrench.and.screwdriver.fill")
            })
            Tab(value: .settings){
                SettingsView()
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

