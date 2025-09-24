import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 0

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
    @State private var isToolViewActive = false
    @State private var showToolClosePrompt = false

    @AppStorage("accentColor") private var accentRaw = AccentColorOption.purple.rawValue
    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("showGuidedTips") private var showGuidedTips = true
    @State private var showOnboarding = false

    @Environment(\.colorScheme) private var colorScheme
    private var background: Color { AppStyle.background(for: colorScheme) }
    private var primary: Color { AppStyle.primary(for: colorScheme) }

    private var favoriteTools: [ToolItem] { tools.filter { favoriteToolIDs.contains($0.id) } }
    private var recentTools: [ToolItem] {
        recentToolIDs.compactMap { id in tools.first(where: { $0.id == id }) }
    }
    private var activeTool: ToolItem? {
        guard let activeToolID else { return nil }
        return tools.first(where: { $0.id == activeToolID })
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
                        homeTab.tag(0)
                        toolsTab.tag(1)
                        SettingsView(scrollToTopTrigger: $settingsScrollTrigger)
                            .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.3), value: selectedTab)

                    if let tool = activeTool, isToolViewActive {
                        ActiveToolContainer(
                            tool: tool,
                            accent: accent.color,
                            primary: primary,
                            colorScheme: colorScheme,
                            onClose: {
                                closeActiveTool()
                            }
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(1)
                    }

                    VStack {
                        Spacer()
                        bottomBar
                    }
                    .zIndex(2)
                }
            }
            .overlay(alignment: .center) {
                if showToolClosePrompt {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                                showToolClosePrompt = false
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
    }

    private var header: some View {
        HStack(alignment: .center) {
            ZStack(alignment: .leading) {
                Text("Home")
                    .opacity(selectedTab == 0 ? 1 : 0)
                Text("Tools")
                    .opacity(selectedTab == 1 ? 1 : 0)
                Text("Settings")
                    .opacity(selectedTab == 2 ? 1 : 0)
            }
            .font(.system(size: 46, weight: .heavy, design: .rounded))
            .tracking(0.5)
            .foregroundStyle(primary)
            .padding(.leading, 22)
            .appTextShadow(colorScheme: colorScheme)
            .animation(.easeInOut(duration: 0.25), value: selectedTab)

            Spacer()

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
            onShowTools: { selectedTab = 1 }
        )
    }

    private var toolsTab: some View {
        ToolsView(
            tools: tools,
            selectedTool: $selectedTool,
            activeTool: $activeToolID,
            scrollToTopTrigger: $toolsScrollTrigger,
            accent: accent,
            primary: primary,
            colorScheme: colorScheme
        ) { tool, isNewSelection in
            let text = isNewSelection ? "\(tool.title) ready." : "\(tool.title) already active."
            presentToast(text, color: accent.color)
        } onOpen: { tool in
            launchTool(tool, showToast: false)
        } onClose: { identifier in
            if activeToolID == identifier {
                closeActiveTool()
            }
        }
    }

    private var bottomBar: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [background, background.opacity(0.0)]),
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 88)
            .ignoresSafeArea(edges: .bottom)

            HStack(spacing: 28) {
                Spacer()

                if let tool = activeToolID.flatMap({ id in tools.first(where: { $0.id == id }) }) {
                    ToolDockIcon(
                        tool: tool,
                        isActive: isToolViewActive,
                        showClose: showToolClosePrompt,
                        accent: accent.color,
                        primary: primary,
                        onActivate: {
                            activateToolFromDock()
                        },
                        onToggleClose: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                                showToolClosePrompt.toggle()
                            }
                        },
                        onClose: {
                            closeActiveTool()
                        }
                    )
                }

                bottomTabButton(systemName: "house.fill", tab: 0, trigger: $homeScrollTrigger)
                bottomTabButton(systemName: "wrench.and.screwdriver.fill", tab: 1, trigger: $toolsScrollTrigger)
                bottomTabButton(systemName: "gearshape.fill", tab: 2, trigger: $settingsScrollTrigger)

                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 14)
        }
    }

    private func bottomTabButton(systemName: String, tab: Int, trigger: Binding<Bool>) -> some View {
        Button(action: {
            HapticsManager.shared.pulse()
            if showToolClosePrompt {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                    showToolClosePrompt = false
                }
            }
            if isToolViewActive {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                    isToolViewActive = false
                }
            }
            if selectedTab == tab {
                trigger.wrappedValue.toggle()
            } else {
                selectedTab = tab
                DispatchQueue.main.async {
                    trigger.wrappedValue.toggle()
                }
            }
        }) {
            Image(systemName: systemName)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(selectedTab == tab ? accent.color : primary.opacity(0.5))
                .animation(.easeInOut(duration: 0.25), value: selectedTab)
        }
    }

    private func launchTool(_ tool: ToolItem, showToast: Bool = true) {
        if selectedTool != tool.id {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                selectedTool = tool.id
            }
        } else {
            selectedTool = tool.id
        }
        updateRecents(with: tool.id)

        withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
            activeToolID = tool.id
            isToolViewActive = true
            showToolClosePrompt = false
        }

        if selectedTab != 1 {
            selectedTab = 1
        }

        if showToast {
            presentToast("\(tool.title) ready.", color: accent.color)
        }
    }

    private func activateToolFromDock() {
        guard activeToolID != nil else { return }
        if selectedTab != 1 {
            selectedTab = 1
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
            isToolViewActive = true
            showToolClosePrompt = false
        }
    }

    private func closeActiveTool() {
        guard activeToolID != nil else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
            isToolViewActive = false
            showToolClosePrompt = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                activeToolID = nil
            }
        }
    }

    private func toggleFavorite(_ identifier: ToolItem.Identifier) {
        if favoriteToolIDs.contains(identifier) {
            favoriteToolIDs.remove(identifier)
        } else {
            favoriteToolIDs.insert(identifier)
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
}

private struct ActiveToolContainer: View {
    let tool: ToolItem
    let accent: Color
    let primary: Color
    let colorScheme: ColorScheme
    let onClose: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            tool.destination()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppStyle.background(for: colorScheme).ignoresSafeArea())

            Button(action: {
                HapticsManager.shared.selection()
                onClose()
            }) {
                Image(systemName: "xmark.square.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(accent)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: AppStyle.compactCornerRadius, style: .continuous)
                            .fill(primary.opacity(AppStyle.cardFillOpacity))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppStyle.compactCornerRadius, style: .continuous)
                                    .stroke(primary.opacity(AppStyle.strokeOpacity), lineWidth: 1)
                            )
                    )
                    .appShadow(colorScheme: colorScheme, level: .medium, opacity: 0.35)
            }
            .buttonStyle(.plain)
            .padding(.top, 28)
            .padding(.trailing, 24)
        }
    }
}

private struct ToolDockIcon: View {
    let tool: ToolItem
    let isActive: Bool
    let showClose: Bool
    let accent: Color
    let primary: Color
    let onActivate: () -> Void
    let onToggleClose: () -> Void
    let onClose: () -> Void

    var body: some View {
        ZStack {
            if showClose {
                Button(action: {
                    HapticsManager.shared.selection()
                    onClose()
                }) {
                    iconBackground(color: primary.opacity(AppStyle.cardFillOpacity)) {
                        Image(systemName: "xmark.square.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(accent)
                    }
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            } else if isActive {
                Button(action: {
                    HapticsManager.shared.selection()
                    onToggleClose()
                }) {
                    RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                        .fill(LinearGradient(colors: tool.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 56, height: 56)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )
                        .overlay(
                            Image(systemName: tool.iconName)
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            } else {
                Button(action: {
                    HapticsManager.shared.selection()
                    onActivate()
                }) {
                    iconBackground(color: accent.opacity(0.18)) {
                        Image(systemName: "arrow.up.right.square.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(accent)
                    }
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 58, height: 58)
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: showClose)
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: isActive)
    }

    private func iconBackground<Content: View>(color: Color, @ViewBuilder content: () -> Content) -> some View {
        RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
            .fill(color)
            .frame(width: 56, height: 56)
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                    .stroke(primary.opacity(AppStyle.strokeOpacity), lineWidth: 1)
            )
            .overlay(content())
            .shadow(color: primary.opacity(0.15), radius: 12, x: 0, y: 6)
    }
}

#Preview { ContentView() }
