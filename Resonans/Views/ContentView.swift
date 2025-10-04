import SwiftUI

struct ContentView: View {
    private enum TabSelection: CaseIterable, Hashable {
        case home
        case tools
        case settings

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .tools: return "wrench.and.screwdriver.fill"
            case .settings: return "gearshape.fill"
            }
        }

        var title: String {
            switch self {
            case .home: return "Home"
            case .tools: return "Tools"
            case .settings: return "Settings"
            }
        }
    }

    @State private var selectedTab: TabSelection = .home

    @State private var homeScrollTrigger = false
    @State private var toolsScrollTrigger = false
    @State private var settingsScrollTrigger = false

    private let tools = ToolItem.all
    @State private var selectedTool: ToolItem.Identifier = .audioExtractor
    @State private var favoriteToolIDs: Set<ToolItem.Identifier> = [.audioExtractor]
    @State private var recentToolIDs: [ToolItem.Identifier] = CacheManager.shared.loadRecentTools()
    @State private var activeTool: ToolItem?

    @AppStorage("accentColor") private var accentRaw = AccentColorOption.purple.rawValue
    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("showGuidedTips") private var showGuidedTips = true
    @State private var showOnboarding = false

    @Environment(\.colorScheme) private var colorScheme
    private var background: Color { AppStyle.background(for: colorScheme) }
    private var primary: Color { AppStyle.primary(for: colorScheme) }

    private var favoriteTools: [ToolItem] {
        tools.filter { favoriteToolIDs.contains($0.id) }
    }

    private var recentTools: [ToolItem] {
        recentToolIDs.compactMap { id in tools.first(where: { $0.id == id }) }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [accent.color.opacity(colorScheme == .dark ? 0.28 : 0.16), background],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                TabView(selection: $selectedTab) {
                    homeTab.tag(TabSelection.home)
                    toolsTab.tag(TabSelection.tools)
                    SettingsView(scrollToTopTrigger: $settingsScrollTrigger)
                        .tag(TabSelection.settings)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut(duration: 0.25), value: selectedTab)
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
        .tint(accent.color)
        .animation(.easeInOut(duration: 0.4), value: colorScheme)
        .animation(.easeInOut(duration: 0.4), value: accent)
        .contentShape(Rectangle())
        .onAppear {
            if !hasCompletedOnboarding {
                showOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingFlowView(
                tools: tools,
                accent: accent.color,
                primary: primary,
                colorScheme: colorScheme
            ) { favorites, tips in
                favoriteToolIDs = favorites
                showGuidedTips = tips
                hasCompletedOnboarding = true
                showOnboarding = false
                HapticsManager.shared.notify(.success)
            }
        }
        .sheet(item: $activeTool) { tool in
            ToolSheetContainer(
                tool: tool,
                accent: accent.color,
                colorScheme: colorScheme
            ) {
                closeActiveTool()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Resonans")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(primary)
            Text(headerSubtitle)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(primary.opacity(0.65))
                .animation(.easeInOut(duration: 0.2), value: selectedTab)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 28)
        .padding(.top, 32)
        .padding(.bottom, 18)
        .background(
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(primary.opacity(AppStyle.cardFillOpacity * 0.5))
                .blur(radius: 30)
                .opacity(0.6)
                .allowsHitTesting(false)
        )
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            tabButton(for: .home, trigger: $homeScrollTrigger)
            tabButton(for: .tools, trigger: $toolsScrollTrigger)
            tabButton(for: .settings, trigger: $settingsScrollTrigger)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(background.opacity(colorScheme == .dark ? 0.55 : 0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(primary.opacity(AppStyle.strokeOpacity), lineWidth: 1)
                )
                .shadow(
                    color: AppStyle.shadowColor(for: colorScheme).opacity(colorScheme == .dark ? 0.6 : 0.18),
                    radius: 22,
                    x: 0,
                    y: 18
                )
        )
        .padding(.horizontal, 32)
        .padding(.bottom, 12)
        .animation(.easeInOut(duration: 0.3), value: selectedTab)
    }

    private func tabButton(for tab: TabSelection, trigger: Binding<Bool>) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            if isSelected {
                trigger.wrappedValue.toggle()
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    selectedTab = tab
                }
                HapticsManager.shared.selection()
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSelected ? accent.color : primary.opacity(0.75))
                    .frame(width: 42, height: 42)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(accent.color.opacity(isSelected ? 0.24 : 0.08))
                    )
                    .scaleEffect(isSelected ? 1.05 : 1.0)
                Text(tab.title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? accent.color : primary.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var homeTab: some View {
        HomeDashboardView(
            favoriteTools: favoriteTools,
            recentTools: recentTools,
            scrollToTopTrigger: $homeScrollTrigger,
            accent: accent,
            primary: primary,
            colorScheme: colorScheme,
            onOpenTool: openTool,
            onShowTools: { switchToTab(.tools) }
        )
    }

    private var toolsTab: some View {
        ToolsView(
            tools: tools,
            selectedTool: $selectedTool,
            scrollToTopTrigger: $toolsScrollTrigger,
            accent: accent,
            primary: primary,
            colorScheme: colorScheme,
            favorites: favoriteToolIDs,
            onOpen: openTool
        )
    }

    private var headerSubtitle: String {
        switch selectedTab {
        case .home:
            return "Your creative command centre"
        case .tools:
            return "Launch a workflow in a tap"
        case .settings:
            return "Tweak the experience to fit you"
        }
    }

    private func switchToTab(_ tab: TabSelection) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            selectedTab = tab
        }
    }

    private func openTool(_ tool: ToolItem) {
        if selectedTool != tool.id {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                selectedTool = tool.id
            }
        }

        HapticsManager.shared.selection()
        activeTool = tool
        updateRecents(with: tool.id)
    }

    private func closeActiveTool() {
        withAnimation(.easeInOut(duration: 0.2)) {
            activeTool = nil
        }
    }

    private func updateRecents(with identifier: ToolItem.Identifier) {
        if let existingIndex = recentToolIDs.firstIndex(of: identifier) {
            recentToolIDs.remove(at: existingIndex)
        }
        recentToolIDs.insert(identifier, at: 0)
        CacheManager.shared.saveRecentTools(recentToolIDs)
    }
}

private struct ToolSheetContainer: View {
    let tool: ToolItem
    let accent: Color
    let colorScheme: ColorScheme
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            tool.destination(onClose)
                .navigationTitle(tool.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            HapticsManager.shared.selection()
                            onClose()
                        } label: {
                            Label("Close", systemImage: "xmark")
                                .labelStyle(.titleAndIcon)
                        }
                    }
                }
                .toolbarBackground(AppStyle.background(for: colorScheme), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        }
        .tint(accent)
    }
}

#Preview {
    ContentView()
}
