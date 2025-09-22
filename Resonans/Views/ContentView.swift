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
    @State private var newsItems: [AppNewsItem] = [
        AppNewsItem(
            title: "Interactive onboarding arrives",
            description: "Learn the essentials of Resonans with a guided tour that adapts to your creative flow.",
            date: Date()
        ),
        AppNewsItem(
            title: "Audio extractor gets a fresh coat",
            description: "A new streamlined launcher with quick file access keeps your exports on point.",
            date: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()
        )
    ]

    @State private var toolLaunchRequest: ToolItem.Identifier?

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
                                bottomTabButton(systemName: "house.fill", tab: 0, trigger: $homeScrollTrigger)
                                Spacer()
                                bottomTabButton(systemName: "wrench.and.screwdriver.fill", tab: 1, trigger: $toolsScrollTrigger)
                                Spacer()
                                bottomTabButton(systemName: "gearshape.fill", tab: 2, trigger: $settingsScrollTrigger)
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
            favoriteTools: favoriteTools,
            recentTools: recentTools,
            newsItems: newsItems,
            scrollToTopTrigger: $homeScrollTrigger,
            accent: accent,
            primary: primary,
            colorScheme: colorScheme,
            onOpenTool: { launchTool($0) },
            onToggleFavorite: { toggleFavorite($0) },
            onShowTools: { selectedTab = 1 }
        )
    }

    private var toolsTab: some View {
        ToolsView(
            tools: tools,
            selectedTool: $selectedTool,
            scrollToTopTrigger: $toolsScrollTrigger,
            pendingLaunch: $toolLaunchRequest,
            accent: accent,
            primary: primary,
            colorScheme: colorScheme
        ) { tool, isNewSelection in
            let text = isNewSelection ? "\(tool.title) ready." : "\(tool.title) already active."
            presentToast(text, color: accent.color)
        } onOpen: { tool in
            updateRecents(with: tool.id)
        }
    }

    private func bottomTabButton(systemName: String, tab: Int, trigger: Binding<Bool>) -> some View {
        Button(action: {
            HapticsManager.shared.pulse()
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

    private func launchTool(_ tool: ToolItem) {
        selectedTool = tool.id
        updateRecents(with: tool.id)
        presentToast("\(tool.title) ready.", color: accent.color)
        toolLaunchRequest = tool.id
        if selectedTab != 1 {
            selectedTab = 1
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

#Preview { ContentView() }
