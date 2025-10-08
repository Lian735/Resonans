import SwiftUI

struct ContentView: View {
    private enum TabSelection: Hashable {
        case home
        case tools
        case settings
        case tool(ToolItem.Identifier)
    }

    @State private var selectedTab: TabSelection = .home

    @State private var homeScrollTrigger = false
    @State private var toolsScrollTrigger = false
    @State private var settingsScrollTrigger = false

    private let tools = ToolItem.all
    @State private var selectedTool: ToolItem.Identifier = .audioExtractor
    @State private var favoriteToolIDs: Set<ToolItem.Identifier> = [.audioExtractor]
    @State private var recentToolIDs: [ToolItem.Identifier] = CacheManager.shared.loadRecentTools()
    @State private var activeToolID: ToolItem.Identifier?
    @State private var showToolCloseIcon = false
    @State private var shouldSkipCloseReset = false

    @AppStorage("accentColor") private var accentRaw = AccentColorOption.purple.rawValue
    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("showGuidedTips") private var showGuidedTips = true
    @State private var showOnboarding = false

    @Environment(\.colorScheme) private var colorScheme
    private var background: Color { AppStyle.background(for: colorScheme) }
    private var primary: Color { AppStyle.primary(for: colorScheme) }

    private var recentTools: [ToolItem] {
        recentToolIDs.compactMap { id in tools.first(where: { $0.id == id }) }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            backgroundLayer
            VStack(spacing: 0) {
                header
                tabContainer
            }
        }
        .tint(accent.color)
        .animation(.easeInOut(duration: 0.4), value: colorScheme)
        .animation(.easeInOut(duration: 0.4), value: accent)
        .contentShape(Rectangle())
        .onAppear(perform: handleAppear)
        .fullScreenCover(isPresented: $showOnboarding, content: onboardingCover)
        .onChange(of: selectedTab, perform: handleTabChange)
        .onChange(of: activeToolID, perform: handleActiveToolChange)
        .simultaneousGesture(TapGesture().onEnded(handleBackgroundTap))
    }

    // MARK: - View building

    private var backgroundLayer: some View {
        background
            .ignoresSafeArea()
            .overlay(
                LinearGradient(
                    colors: [accent.gradient, .clear],
                    startPoint: .topLeading,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
    }

    private var tabContainer: some View {
        ZStack {
            tabPages
            tabBar
        }
    }

    private var tabPages: some View {
        TabView(selection: $selectedTab) {
            homeTab.tag(TabSelection.home)
            toolsTab.tag(TabSelection.tools)
            toolDetailTab
            SettingsView(scrollToTopTrigger: $settingsScrollTrigger)
                .tag(TabSelection.settings)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .animation(.easeInOut(duration: 0.3), value: selectedTab)
    }

    @ViewBuilder
    private var toolDetailTab: some View {
        if let activeToolID, let tool = tools.first(where: { $0.id == activeToolID }) {
            toolView(for: tool)
                .tag(TabSelection.tool(activeToolID))
        }
    }

    private var tabBar: some View {
        VStack {
            Spacer()
            BottomTabBar(
                background: background,
                accent: accent.color,
                primary: primary,
                selectedTab: selectedTab,
                activeToolID: activeToolID,
                showToolCloseIcon: showToolCloseIcon,
                onHome: { selectTab(.home, trigger: $homeScrollTrigger) },
                onTools: { selectTab(.tools, trigger: $toolsScrollTrigger) },
                onSettings: { selectTab(.settings, trigger: $settingsScrollTrigger) },
                onToolTap: handleToolButtonTap,
                onToolClose: closeActiveTool
            )
            .padding(.horizontal, 40)
            .padding(.vertical, 12)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private func handleAppear() {
        guard !hasCompletedOnboarding else { return }
        showOnboarding = true
    }

    @ViewBuilder
    private func onboardingCover() -> some View {
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

    private func handleTabChange(_ oldValue: TabSelection, _ newValue: TabSelection) {
        guard case .tool = newValue else {
            hideToolCloseIcon()
            return
        }
    }

    private func handleActiveToolChange(
        _ oldValue: ToolItem.Identifier?,
        _ newValue: ToolItem.Identifier?
    ) {
        guard newValue == nil, case .tool = selectedTab else { return }
        selectedTab = .tools
    }

    private func handleBackgroundTap() {
        guard showToolCloseIcon else { return }
        if shouldSkipCloseReset {
            shouldSkipCloseReset = false
            return
        }
        hideToolCloseIcon()
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            Text(headerTitle)
                .font(.system(size: 46, weight: .heavy, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(primary)
                .appTextShadow(colorScheme: colorScheme)
                .animation(.easeInOut(duration: 0.25), value: selectedTab)

            Spacer()

            headerActionButton
        }
        .padding(.horizontal, AppStyle.horizontalPadding)
    }

    private var headerTitle: String {
        switch selectedTab {
        case .home: return "Home"
        case .tools: return "Tools"
        case .settings: return "Settings"
        case let .tool(identifier):
            return tools.first(where: { $0.id == identifier })?.title ?? "Tool"
        }
    }

    @ViewBuilder
    private var headerActionButton: some View {
        switch selectedTab {
        case .tool where activeToolID != nil:
            Button(action: { closeActiveToolWithHaptics() }) {
                headerSymbol("xmark")
            }
            .buttonStyle(.plain)
        case .settings:
            Button(action: { showOnboardingWithHaptics() }) {
                headerSymbol("questionmark.circle")
            }
            .buttonStyle(.plain)
        default:
            EmptyView()
        }
    }

    private func headerSymbol(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 26, weight: .semibold))
            .foregroundStyle(primary)
            .appTextShadow(colorScheme: colorScheme)
    }

    private func closeActiveToolWithHaptics() {
        HapticsManager.shared.selection()
        closeActiveTool()
    }

    private func showOnboardingWithHaptics() {
        HapticsManager.shared.pulse()
        showOnboarding = true
    }

    // MARK: - Tabs

    private var homeTab: some View {
        HomeDashboardView(
            tools: tools,
            recentTools: recentTools,
            scrollToTopTrigger: $homeScrollTrigger,
            accent: accent,
            primary: primary,
            colorScheme: colorScheme,
            onOpenTool: launchTool,
            onShowTools: { navigateToToolsTab() }
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
            activeTool: activeToolID,
            onOpen: launchTool,
            onClose: { identifier in
                guard activeToolID == identifier else { return }
                closeActiveTool()
            }
        )
    }

    private func navigateToToolsTab() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            selectedTab = .tools
        }
        hideToolCloseIcon(animated: false)
        shouldSkipCloseReset = false
    }

    private func selectTab(_ tab: TabSelection, trigger: Binding<Bool>) {
        HapticsManager.shared.pulse()
        if selectedTab == tab {
            trigger.wrappedValue.toggle()
            return
        }

        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            selectedTab = tab
        }

        DispatchQueue.main.async {
            trigger.wrappedValue.toggle()
        }

        shouldSkipCloseReset = false
        hideToolCloseIcon()
    }

    private func handleToolButtonTap(_ identifier: ToolItem.Identifier) {
        HapticsManager.shared.pulse()
        if selectedTab == .tool(identifier) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                showToolCloseIcon = true
            }
            shouldSkipCloseReset = true
            return
        }

        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            selectedTab = .tool(identifier)
        }

        hideToolCloseIcon(animated: false)
        shouldSkipCloseReset = false
    }

    // MARK: - Tool handling

    private func launchTool(_ tool: ToolItem) {
        selectedTool = tool.id
        updateRecents(with: tool.id)
        hideToolCloseIcon(animated: false)
        shouldSkipCloseReset = false
        withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
            activeToolID = tool.id
            selectedTab = .tool(tool.id)
        }
    }

    private func closeActiveTool() {
        guard let identifier = activeToolID else { return }
        hideToolCloseIcon()
        shouldSkipCloseReset = false
        if case let .tool(current) = selectedTab, current == identifier {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                selectedTab = .tools
            }
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
            activeToolID = nil
        }
    }

    private func updateRecents(with identifier: ToolItem.Identifier) {
        recentToolIDs.removeAll(where: { $0 == identifier })
        recentToolIDs.insert(identifier, at: 0)
        if recentToolIDs.count > 6 {
            recentToolIDs = Array(recentToolIDs.prefix(6))
        }
        CacheManager.shared.saveRecentTools(recentToolIDs)
    }

    private func hideToolCloseIcon(animated: Bool = true) {
        guard showToolCloseIcon else { return }
        if animated {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                showToolCloseIcon = false
            }
        } else {
            showToolCloseIcon = false
        }
    }

    @ViewBuilder
    private func toolView(for tool: ToolItem) -> some View {
        switch tool.id {
        case .audioExtractor:
            AudioExtractorView(onClose: closeActiveTool)
        }
    }
}

private struct BottomTabBar: View {
    let background: Color
    let accent: Color
    let primary: Color
    let selectedTab: ContentView.TabSelection
    let activeToolID: ToolItem.Identifier?
    let showToolCloseIcon: Bool
    let onHome: () -> Void
    let onTools: () -> Void
    let onSettings: () -> Void
    let onToolTap: (ToolItem.Identifier) -> Void
    let onToolClose: () -> Void

    var body: some View {
        ZStack {
            backgroundGradient
            HStack {
                Spacer()
                tabButtons
                Spacer()
            }
            .padding(.horizontal, 8)
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: activeToolID)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [background, background.opacity(0.0)]),
            startPoint: .bottom,
            endPoint: .top
        )
        .frame(height: 80)
    }

    @ViewBuilder
    private var tabButtons: some View {
        HStack(spacing: 32) {
            TabButton(
                systemName: "house.fill",
                isSelected: selectedTab == .home,
                accent: accent,
                primary: primary,
                action: onHome
            )
            TabButton(
                systemName: "wrench.and.screwdriver.fill",
                isSelected: selectedTab == .tools,
                accent: accent,
                primary: primary,
                action: onTools
            )
            if let activeToolID {
                ToolToggleButton(
                    isSelected: selectedTab == .tool(activeToolID),
                    accent: accent,
                    primary: primary,
                    showCloseIcon: showToolCloseIcon,
                    onTap: { onToolTap(activeToolID) },
                    onClose: onToolClose
                )
                .transition(.scale.combined(with: .opacity))
            }
            TabButton(
                systemName: "gearshape.fill",
                isSelected: selectedTab == .settings,
                accent: accent,
                primary: primary,
                action: onSettings
            )
        }
    }
}

private struct TabButton: View {
    let systemName: String
    let isSelected: Bool
    let accent: Color
    let primary: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 24, weight: .semibold))
                .scaleEffect(symbolCompensation(for: systemName))
                .foregroundStyle(isSelected ? accent : primary.opacity(0.5))
                .animation(.easeInOut(duration: 0.25), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    private func symbolCompensation(for name: String) -> CGFloat {
        switch name {
        case "arrow.up.right.square.fill", "xmark.square.fill":
            return 1.1
        default:
            return 1.0
        }
    }
}

private struct ToolToggleButton: View {
    let isSelected: Bool
    let accent: Color
    let primary: Color
    let showCloseIcon: Bool
    let onTap: () -> Void
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Button(action: onTap) {
                Image(systemName: "arrow.up.right.square.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .scaleEffect(1.1)
                    .foregroundStyle(isSelected ? accent : primary.opacity(0.5))
            }
            .buttonStyle(.plain)
            .scaleEffect(showCloseIcon && isSelected ? 0.01 : 1)
            .opacity(showCloseIcon && isSelected ? 0 : 1)
            .animation(.spring(response: 0.45, dampingFraction: 0.75), value: showCloseIcon)
            .animation(.easeInOut(duration: 0.25), value: isSelected)

            Button(action: onClose) {
                Image(systemName: "xmark.square.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .scaleEffect(1.1)
                    .foregroundStyle(accent)
            }
            .buttonStyle(.plain)
            .scaleEffect(showCloseIcon && isSelected ? 1 : 0.01)
            .opacity(showCloseIcon && isSelected ? 1 : 0)
            .animation(.spring(response: 0.45, dampingFraction: 0.75), value: showCloseIcon)
        }
    }
}

#Preview { ContentView() }

