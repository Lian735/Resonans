import SwiftUI

struct ContentView: View {
    @StateObject var viewModel: ContentViewModel
    
    @AppStorage("accentColor") private var accentRaw = AccentColorOption.purple.rawValue
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("showGuidedTips") private var showGuidedTips = true

    @Environment(\.colorScheme) private var colorScheme
    private var background: Color { AppStyle.background(for: colorScheme) }
    @available(*, deprecated)
    private var primary: Color { AppStyle.primary(for: colorScheme) }
    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }

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
        .onChange(of: viewModel.selectedTab) { oldValue, newValue in
            guard case .tool = newValue else {
                viewModel.hideToolCloseIcon()
                return
            }
            viewModel.previousSelectedTab = oldValue
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                guard viewModel.showToolCloseIcon else { return }
                if viewModel.shouldSkipCloseReset {
                    viewModel.shouldSkipCloseReset = false
                    return
                }
                viewModel.hideToolCloseIcon()
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
        TabView(selection: $viewModel.selectedTab) {
            homeTab
                .tag(TabSelection.home)
            toolsTab
                .tag(TabSelection.tools)

            if let activeToolID = viewModel.selectedTool,
                let tool = viewModel.tools.first(where: { $0.id == activeToolID }) {
                toolView(for: tool)
                    .tag(TabSelection.tool(activeToolID))
            }

            SettingsView(scrollToTopTrigger: $viewModel.settingsScrollTrigger)
                .tag(TabSelection.settings)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .animation(.easeInOut(duration: 0.3), value: viewModel.selectedTab)
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
            bottomTabButton(systemName: "house.fill", tab: .home, trigger: $viewModel.homeScrollTrigger)
            bottomTabButton(systemName: "wrench.and.screwdriver.fill", tab: .tools, trigger: $viewModel.toolsScrollTrigger)
            if let activeToolID = viewModel.selectedTool {
                toolIconButton(for: activeToolID)
                    .transition(.scale.combined(with: .opacity))
            }
            bottomTabButton(systemName: "gearshape.fill", tab: .settings, trigger: $viewModel.settingsScrollTrigger)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: viewModel.selectedTool)
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text(headerTitle)
                .font(.system(size: 46, weight: .heavy, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(.primary)
                .shadow(ShadowConfiguration.textConfiguration(for: colorScheme))
                .animation(.easeInOut(duration: 0.25), value: viewModel.selectedTab)

            Spacer()

            headerActionButton
        }
        .padding(.horizontal, AppStyle.horizontalPadding)
    }

    @ViewBuilder
    private var headerActionButton: some View {
        switch viewModel.selectedTab {
        case .tool:
            if viewModel.selectedTool != nil {
                Button(action: {
                    HapticsManager.shared.selection()
                    viewModel.closeActiveTool()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.primary)
                        .shadow(ShadowConfiguration.textConfiguration(for: colorScheme))
                }
                .buttonStyle(.plain)
            }
        case .settings:
            Button(action: {
                HapticsManager.shared.pulse()
                viewModel.showOnboarding = true
            }) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.primary)
                    .shadow(ShadowConfiguration.textConfiguration(for: colorScheme))
            }
            .buttonStyle(.plain)
        default:
            EmptyView()
        }
    }

    private var headerTitle: String {
        switch viewModel.selectedTab {
        case .home:
            return "Home"
        case .tools:
            return "Tools"
        case .settings:
            return "Settings"
        case let .tool(identifier):
            return viewModel.tools.first(where: { $0.id == identifier })?.title ?? "Tool"
        }
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

    private var toolsTab: some View {
        ToolsView(
            tools: viewModel.tools,
            selectedTool: $viewModel.selectedTool,
            scrollToTopTrigger: $viewModel.toolsScrollTrigger,
            accent: accent,
            primary: .primary,
            colorScheme: colorScheme,
            activeTool: viewModel.selectedTool,
            onOpen: { tool in
                viewModel.launchTool(tool)
            },
            onClose: { identifier in
                if viewModel.selectedTool == identifier {
                    viewModel.closeActiveTool()
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
            viewModel.tabBarButtonAction(tab: tab, trigger: trigger)
        }) {
            symbolIcon(
                name: systemName,
                size: 24,
                weight: .semibold,
                color: viewModel.selectedTab == tab ? accent.color : primary.opacity(0.5)
            )
            .animation(.easeInOut(duration: 0.25), value: viewModel.selectedTab)
        }
    }

    private func toolIconButton(for identifier: ToolItem.Identifier) -> some View {
        let isSelected: Bool
        if case let .tool(current) = viewModel.selectedTab, current == identifier {
            isSelected = true
        } else {
            isSelected = false
        }
        return Group {
            if viewModel.showToolCloseIcon {
                Button {
                    HapticsManager.shared.pulse()
                    viewModel.closeActiveTool()
                } label: {
                    symbolIcon(
                        name: "xmark.square.fill",
                        size: 24,
                        weight: .semibold,
                        color: accent.color
                    )
                }
                .buttonStyle(.plain)
                .animation(.spring(response: 0.45, dampingFraction: 0.75), value: viewModel.showToolCloseIcon)
            } else {
                Button {
                    HapticsManager.shared.pulse()
                    viewModel.toolButtonAction(isSelected: isSelected, identifier: identifier)
                } label: {
                    symbolIcon(
                        name: "arrow.up.right.square.fill",
                        size: 24,
                        weight: .semibold,
                        color: isSelected ? accent.color : primary.opacity(0.5)
                    )
                }
                .buttonStyle(.plain)
                .animation(.spring(response: 0.45, dampingFraction: 0.75), value: viewModel.showToolCloseIcon)
                .animation(.easeInOut(duration: 0.25), value: viewModel.selectedTab)
            }
        }
    }

    @ViewBuilder
    private func toolView(for tool: ToolItem) -> some View {
        switch tool.id {
        case .audioExtractor:
            AudioExtractorView(onClose: { viewModel.closeActiveTool() })
        case .dummy:
            DummyToolView(onClose: { viewModel.closeActiveTool() })
        }
    }
}

#Preview { ContentView(viewModel: ContentViewModel()) }

