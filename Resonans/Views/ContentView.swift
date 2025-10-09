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
            backgroundView
            mainContent
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
        .onChange(of: selectedTab) { _, newValue in
            guard case .tool = newValue else {
                hideToolCloseIcon()
                return
            }
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                guard showToolCloseIcon else { return }
                if shouldSkipCloseReset {
                    shouldSkipCloseReset = false
                    return
                }
                hideToolCloseIcon()
            }
        )
    }

    private var backgroundView: some View {
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

    private var mainContent: some View {
        VStack(spacing: 0) {
            header
            ZStack {
                tabs
                tabBarOverlay
            }
        }
    }

    private var tabs: some View {
        TabView(selection: $selectedTab) {
            homeTab
                .tag(TabSelection.home)
            toolsTab
                .tag(TabSelection.tools)

            if let activeToolID, let tool = tools.first(where: { $0.id == activeToolID }) {
                toolView(for: tool)
                    .tag(TabSelection.tool(activeToolID))
            }

            SettingsView(scrollToTopTrigger: $settingsScrollTrigger)
                .tag(TabSelection.settings)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .animation(.easeInOut(duration: 0.3), value: selectedTab)
    }

    private var tabBarOverlay: some View {
        VStack {
            Spacer()
            LinearGradient(
                gradient: Gradient(colors: [background, background.opacity(0)]),
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 80)
            .ignoresSafeArea(edges: .bottom)
            .overlay(alignment: .center) { tabBar }
        }
    }

    private var tabBar: some View {
        HStack(spacing: 32) {
            bottomTabButton(systemName: "house.fill", tab: .home, trigger: $homeScrollTrigger)
            bottomTabButton(systemName: "wrench.and.screwdriver.fill", tab: .tools, trigger: $toolsScrollTrigger)
            if let activeToolID {
                toolIconButton(for: activeToolID)
                    .transition(.scale.combined(with: .opacity))
            }
            bottomTabButton(systemName: "gearshape.fill", tab: .settings, trigger: $settingsScrollTrigger)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: activeToolID)
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text(headerTitle)
                .font(.system(size: 46, weight: .heavy, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(primary)
                .shadow(ShadowConfiguration.textConfiguration(for: colorScheme))
                .animation(.easeInOut(duration: 0.25), value: selectedTab)

            Spacer()

            headerActionButton
        }
        .padding(.horizontal, AppStyle.horizontalPadding)
    }

    @ViewBuilder
    private var headerActionButton: some View {
        switch selectedTab {
        case .tool:
            if activeToolID != nil {
                Button(action: {
                    HapticsManager.shared.selection()
                    closeActiveTool()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(primary)
                        .shadow(ShadowConfiguration.textConfiguration(for: colorScheme))
                }
                .buttonStyle(.plain)
            }
        case .settings:
            Button(action: {
                HapticsManager.shared.pulse()
                showOnboarding = true
            }) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(primary)
                    .shadow(ShadowConfiguration.textConfiguration(for: colorScheme))
            }
            .buttonStyle(.plain)
        default:
            EmptyView()
        }
    }

    private var headerTitle: String {
        switch selectedTab {
        case .home:
            return "Home"
        case .tools:
            return "Tools"
        case .settings:
            return "Settings"
        case let .tool(identifier):
            return tools.first(where: { $0.id == identifier })?.title ?? "Tool"
        }
    }

    private var homeTab: some View {
        HomeDashboardView(
            tools: tools,
            recentTools: recentTools,
            scrollToTopTrigger: $homeScrollTrigger,
            accent: accent,
            primary: primary,
            colorScheme: colorScheme,
            onOpenTool: { launchTool($0) },
            onShowTools: {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                    selectedTab = .tools
                }
            }
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
            onOpen: { tool in
                launchTool(tool)
            },
            onClose: { identifier in
                if activeToolID == identifier {
                    closeActiveTool()
                }
            }
        )
    }

    private func symbolCompensation(for name: String) -> CGFloat {
        switch name {
        case "arrow.up.right.square.fill", "xmark.square.fill":
            return 1.1
        default:
            return 1.0
        }
    }

    private func symbolIcon(name: String, size: CGFloat, weight: Font.Weight, color: Color) -> some View {
        Image(systemName: name)
            .font(.system(size: size, weight: weight))
            .scaleEffect(symbolCompensation(for: name))
            .foregroundStyle(color)
    }

    private func bottomTabButton(systemName: String, tab: TabSelection, trigger: Binding<Bool>) -> some View {
        Button(action: {
            HapticsManager.shared.pulse()
            if selectedTab == tab {
                trigger.wrappedValue.toggle()
            } else {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                    selectedTab = tab
                }
                DispatchQueue.main.async {
                    trigger.wrappedValue.toggle()
                }
            }
            if showToolCloseIcon {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                    showToolCloseIcon = false
                }
            }
            shouldSkipCloseReset = false
        }) {
            symbolIcon(
                name: systemName,
                size: 24,
                weight: .semibold,
                color: selectedTab == tab ? accent.color : primary.opacity(0.5)
            )
            .animation(.easeInOut(duration: 0.25), value: selectedTab)
        }
    }

    private func toolIconButton(for identifier: ToolItem.Identifier) -> some View {
        let isSelected: Bool
        if case let .tool(current) = selectedTab, current == identifier {
            isSelected = true
        } else {
            isSelected = false
        }
        return ZStack {
            Button {
                HapticsManager.shared.pulse()
                if isSelected {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                        showToolCloseIcon = true
                    }
                    shouldSkipCloseReset = true
                } else {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                        selectedTab = .tool(identifier)
                    }
                    if showToolCloseIcon {
                        showToolCloseIcon = false
                    }
                    shouldSkipCloseReset = false
                }
            } label: {
                symbolIcon(
                    name: "arrow.up.right.square.fill",
                    size: 24,
                    weight: .semibold,
                    color: isSelected ? accent.color : primary.opacity(0.5)
                )
            }
            .buttonStyle(.plain)
            .scaleEffect(showToolCloseIcon && isSelected ? 0.01 : 1)
            .opacity(showToolCloseIcon && isSelected ? 0 : 1)
            .animation(.spring(response: 0.45, dampingFraction: 0.75), value: showToolCloseIcon)
            .animation(.easeInOut(duration: 0.25), value: selectedTab)

            Button {
                HapticsManager.shared.pulse()
                closeActiveTool()
            } label: {
                symbolIcon(
                    name: "xmark.square.fill",
                    size: 24,
                    weight: .semibold,
                    color: accent.color
                )
            }
            .buttonStyle(.plain)
            .scaleEffect(showToolCloseIcon && isSelected ? 1 : 0.01)
            .opacity(showToolCloseIcon && isSelected ? 1 : 0)
            .animation(.spring(response: 0.45, dampingFraction: 0.75), value: showToolCloseIcon)
        }
    }

    private func launchTool(_ tool: ToolItem) {
        selectedTool = tool.id
        updateRecents(with: tool.id)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
            activeToolID = tool.id
            selectedTab = .tool(tool.id)
        }
        showToolCloseIcon = false
        shouldSkipCloseReset = false
    }

    private func hideToolCloseIcon() {
        guard showToolCloseIcon else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
            showToolCloseIcon = false
        }
    }

    private func closeActiveTool() {
        guard let identifier = activeToolID else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            showToolCloseIcon = false
        }
        shouldSkipCloseReset = false
        if case let .tool(current) = selectedTab, current == identifier {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                selectedTab = .tools
            }
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
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

    @ViewBuilder
    private func toolView(for tool: ToolItem) -> some View {
        switch tool.id {
        case .audioExtractor:
            AudioExtractorView(onClose: { closeActiveTool() })
        case .dummy:
            DummyToolView(onClose: { closeActiveTool() })
        }
    }
}

#Preview { ContentView() }

