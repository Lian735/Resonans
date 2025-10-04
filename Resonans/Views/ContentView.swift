import SwiftUI

struct ContentView: View {
    private enum Section: String, CaseIterable, Identifiable {
        case overview
        case tools
        case settings

        var id: Self { self }

        var title: String {
            switch self {
            case .overview: return "Home"
            case .tools: return "Tools"
            case .settings: return "Settings"
            }
        }

        var subtitle: String {
            switch self {
            case .overview: return "A calm place for every workflow"
            case .tools: return "Pick the right helper for the job"
            case .settings: return "Personalise Resonans to you"
            }
        }
    }

    @AppStorage("accentColor") private var accentRaw = AccentColorOption.purple.rawValue
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("showGuidedTips") private var showGuidedTips = true
    @AppStorage("appearance") private var appearanceRaw = Appearance.system.rawValue
    @AppStorage("favoriteToolsRaw") private var favoriteToolsRaw = ToolItem.Identifier.audioExtractor.rawValue

    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }
    private var appearance: Appearance { Appearance(rawValue: appearanceRaw) ?? .system }

    @State private var selection: Section = .overview
    @State private var navigationPath: [ToolItem.Identifier] = []
    @State private var recentToolIDs: [ToolItem.Identifier] = CacheManager.shared.loadRecentTools()
    @State private var favoriteToolIDs: Set<ToolItem.Identifier> = []
    @State private var showOnboarding = false

    private let tools = ToolItem.all
    @Environment(\.colorScheme) private var colorScheme
    private var backgroundColor: Color { AppStyle.background(for: colorScheme) }
    private var primary: Color { AppStyle.primary(for: colorScheme) }

    private var favorites: [ToolItem] {
        let ids = favoriteToolIDs
        return tools.filter { ids.contains($0.id) }
    }

    private var recents: [ToolItem] {
        recentToolIDs.compactMap { identifier in
            tools.first(where: { $0.id == identifier })
        }
    }

    @Namespace private var sectionNamespace

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .top) {
                backgroundLayer

                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, AppStyle.horizontalPadding)
                        .padding(.top, 36)
                        .padding(.bottom, 20)

                    sectionPicker
                        .padding(.horizontal, AppStyle.horizontalPadding)

                    content
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 24)
                }
            }
            .navigationDestination(for: ToolItem.Identifier.self) { identifier in
                toolDestination(for: identifier)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(appearance.colorScheme)
        .tint(accent.color)
        .onAppear {
            if favoriteToolIDs.isEmpty {
                favoriteToolIDs = loadFavoriteIDs()
            }
            recentToolIDs = CacheManager.shared.loadRecentTools()
            if !hasCompletedOnboarding {
                showOnboarding = true
            }
        }
        .onChange(of: favoriteToolIDs) { _, newValue in
            storeFavoriteIDs(newValue)
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingFlowView(
                tools: tools,
                accent: accent.color,
                primary: primary,
                colorScheme: colorScheme
            ) { favorites, tips in
                let normalizedFavorites = favorites.isEmpty ? Set([ToolItem.Identifier.audioExtractor]) : favorites
                favoriteToolIDs = normalizedFavorites
                showGuidedTips = tips
                hasCompletedOnboarding = true
                showOnboarding = false
                HapticsManager.shared.notify(.success)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Resonans")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(primary.opacity(0.7))
                    .appTextShadow(colorScheme: colorScheme)
                Text(selection.title)
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .foregroundStyle(primary)
                    .appTextShadow(colorScheme: colorScheme)
                    .animation(.easeInOut(duration: 0.25), value: selection)
                Text(selection.subtitle)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(primary.opacity(0.7))
                    .animation(.easeInOut(duration: 0.25), value: selection)
            }

            Spacer()

            if selection == .settings {
                Button {
                    HapticsManager.shared.pulse()
                    showOnboarding = true
                } label: {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(accent.color)
                        .padding(12)
                        .background(
                            Circle()
                                .fill(primary.opacity(AppStyle.subtleCardFillOpacity))
                        )
                        .appShadow(colorScheme: colorScheme, level: .small, opacity: 0.4)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private var sectionPicker: some View {
        HStack(spacing: 12) {
            ForEach(Section.allCases) { section in
                Button {
                    guard selection != section else { return }
                    HapticsManager.shared.selection()
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                        selection = section
                    }
                } label: {
                    Text(section.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(selection == section ? primary : primary.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            ZStack {
                                if selection == section {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(accent.color.opacity(colorScheme == .dark ? 0.3 : 0.2))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                .stroke(accent.color.opacity(0.35), lineWidth: 1)
                                        )
                                        .matchedGeometryEffect(id: "sectionSelection", in: sectionNamespace)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(primary.opacity(AppStyle.subtleCardFillOpacity))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(primary.opacity(AppStyle.strokeOpacity), lineWidth: 1)
                )
        )
        .appShadow(colorScheme: colorScheme, level: .small, opacity: 0.35)
    }

    @ViewBuilder
    private var content: some View {
        ZStack {
            switch selection {
            case .overview:
                HomeDashboardView(
                    favorites: favorites,
                    recents: recents,
                    accent: accent,
                    primary: primary,
                    colorScheme: colorScheme,
                    onOpenTool: openTool,
                    onShowTools: {
                        withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                            selection = .tools
                        }
                    }
                )
                .transition(.opacity.combined(with: .move(edge: .leading)))
            case .tools:
                ToolsView(
                    tools: tools,
                    favorites: favoriteToolIDs,
                    accent: accent,
                    primary: primary,
                    colorScheme: colorScheme,
                    onOpen: openTool,
                    onToggleFavorite: toggleFavorite
                )
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            case .settings:
                SettingsView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: selection)
    }

    private var backgroundLayer: some View {
        ZStack {
            backgroundColor
            LinearGradient(
                colors: [
                    accent.color.opacity(colorScheme == .dark ? 0.34 : 0.2),
                    accent.gradient,
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }

    private func openTool(_ tool: ToolItem) {
        updateRecents(with: tool.id)
        if navigationPath.last != tool.id {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                navigationPath = [tool.id]
            }
        }
    }

    private func toggleFavorite(_ identifier: ToolItem.Identifier) {
        if favoriteToolIDs.contains(identifier) {
            favoriteToolIDs.remove(identifier)
            if favoriteToolIDs.isEmpty {
                favoriteToolIDs = [.audioExtractor]
            }
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
        CacheManager.shared.saveRecentTools(recentToolIDs)
    }

    @ViewBuilder
    private func toolDestination(for identifier: ToolItem.Identifier) -> some View {
        if let tool = tools.first(where: { $0.id == identifier }) {
            tool.destination {
                withAnimation(.easeInOut(duration: 0.25)) {
                    navigationPath.removeAll(where: { $0 == identifier })
                }
            }
            .navigationTitle(tool.title)
            .navigationBarTitleDisplayMode(.inline)
        } else {
            EmptyView()
        }
    }

    private func loadFavoriteIDs() -> Set<ToolItem.Identifier> {
        let components = favoriteToolsRaw.split(separator: ",").map(String.init)
        let identifiers = components.compactMap { ToolItem.Identifier(rawValue: $0) }
        if identifiers.isEmpty {
            return [.audioExtractor]
        }
        return Set(identifiers)
    }

    private func storeFavoriteIDs(_ newValue: Set<ToolItem.Identifier>) {
        let normalized = newValue.isEmpty ? Set([ToolItem.Identifier.audioExtractor]) : newValue
        let raw = normalized
            .map { $0.rawValue }
            .sorted()
            .joined(separator: ",")
        favoriteToolsRaw = raw
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
