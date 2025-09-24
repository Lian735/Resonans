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

    @State private var message: String?
    @State private var showToast = false
    @State private var toastColor: Color = .green

    private let tools = ToolItem.all
    @State private var selectedTool: ToolItem.Identifier = .audioExtractor
    @State private var favoriteToolIDs: Set<ToolItem.Identifier> = [.audioExtractor]
    @State private var recentToolIDs: [ToolItem.Identifier] = []
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
            background.ignoresSafeArea()
                .overlay(
                    LinearGradient(
                        colors: [accent.gradient, .clear],
                        startPoint: .topLeading,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )

            VStack(spacing: 0) {
                header
                ZStack {
                    TabView(selection: $selectedTab) {
                        homeTab.tag(TabSelection.home)
                        toolsTab.tag(TabSelection.tools)
                        SettingsView(scrollToTopTrigger: $settingsScrollTrigger)
                            .tag(TabSelection.settings)

                        if let activeToolID, let tool = tools.first(where: { $0.id == activeToolID }) {
                            toolView(for: tool)
                                .tag(TabSelection.tool(activeToolID))
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.3), value: selectedTab)

                    VStack {
                        Spacer()
                        ZStack {
                            LinearGradient(
                                gradient: Gradient(colors: [background, background.opacity(0.0)]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                            .frame(height: 80)
                            .ignoresSafeArea(edges: .bottom)

                            HStack {
                                Spacer()
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
                                .animation(.spring(response: 0.45, dampingFraction: 0.8), value: activeToolID)
                                Spacer()
                            }
                            .padding(.horizontal, 40)
                            .padding(.vertical, 12)
                        }
                    }
                }
            }

            if showToast, let msg = message {
                VStack {
                    HStack {
                        Spacer()
                        Text(msg)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(toastColor.opacity(0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        Spacer()
                    }
                    .padding(.top, 44)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation {
                            showToast = false
                        }
                    }
                }
            }
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
                presentToast("You're all set! Let's create.", color: accent.color)
            }
        }
        .onChange(of: selectedTab) { _, newValue in
            if case .tool = newValue {
                return
            }
            if showToolCloseIcon {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                    showToolCloseIcon = false
                }
            }
        }
        .onChange(of: activeToolID) { _, newValue in
            if newValue == nil, case .tool = selectedTab {
                selectedTab = .tools
            }
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                guard showToolCloseIcon else { return }
                if shouldSkipCloseReset {
                    shouldSkipCloseReset = false
                    return
                }
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                    showToolCloseIcon = false
                }
            }
        )
    }

    private var header: some View {
        HStack(alignment: .center) {
            ZStack(alignment: .leading) {
                Text("Home")
                    .opacity(selectedTab == .home ? 1 : 0)
                Text("Tools")
                    .opacity(selectedTab == .tools ? 1 : 0)
                Text("Settings")
                    .opacity(selectedTab == .settings ? 1 : 0)
                if case .tool = selectedTab {
                    Text("Tool")
                        .opacity(1)
                }
            }
            .font(.system(size: 46, weight: .heavy, design: .rounded))
            .tracking(0.5)
            .foregroundStyle(primary)
            .padding(.leading, 22)
            .appTextShadow(colorScheme: colorScheme)
            .animation(.easeInOut(duration: 0.25), value: selectedTab)

            Spacer()

            headerActionButton
        }
    }

    @ViewBuilder
    private var headerActionButton: some View {
        if activeToolID != nil {
            Button(action: {
                HapticsManager.shared.selection()
                closeActiveTool()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(primary)
                    .appTextShadow(colorScheme: colorScheme)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 22)
        } else if selectedTab == .settings {
            Button(action: {
                HapticsManager.shared.pulse()
                showOnboarding = true
            }) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(primary)
                    .appTextShadow(colorScheme: colorScheme)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 22)
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
            activeTool: activeToolID
        ) { tool, isNewSelection in
            let text = isNewSelection ? "\(tool.title) ready." : "\(tool.title) already active."
            presentToast(text, color: accent.color)
        } onOpen: { tool in
            launchTool(tool)
        } onClose: { identifier in
            if activeToolID == identifier {
                closeActiveTool()
            }
        }
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
            Image(systemName: systemName)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(selectedTab == tab ? accent.color : primary.opacity(0.5))
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
                Image(systemName: "arrow.up.right.square.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(isSelected ? accent.color : primary.opacity(0.5))
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
                Image(systemName: "xmark.square.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(accent.color)
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
        presentToast("\(tool.title) ready.", color: accent.color)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
            activeToolID = tool.id
            selectedTab = .tool(tool.id)
        }
        showToolCloseIcon = false
        shouldSkipCloseReset = false
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
    }

    private func presentToast(_ text: String, color: Color) {
        message = text
        toastColor = color

        if showToast {
            showToast = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                    showToast = true
                }
            }
        } else {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                showToast = true
            }
        }
    }

    private func toolView(for tool: ToolItem) -> some View {
        tool.destination { closeActiveTool() }
    }
}

#Preview { ContentView() }
