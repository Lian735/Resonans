import SwiftUI

/// Home screen highlighting onboarding actions, favorites, and recent tools.
struct HomeDashboardView: View {

    let accent: AccentColorOption
    let primary: Color
    
    private var versionDisplayString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        if let version = version, !version.isEmpty {
            if let build = build, !build.isEmpty {
                return "v\(version).\(build)"
            }
            return version
        }
        return "—"
    }
    
    @Environment(\.colorScheme) private var colorScheme
    
    @EnvironmentObject private var viewModel: ContentViewModel
    
    @State private var shimmerPhase: Bool = false
    
    private var favoriteTools: [ToolItem] {
        ToolManager.shared.tools.filter { tool in
            viewModel.favoriteToolIds.contains(tool.id)
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            NavigationStack{
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        homeBox {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Welcome back!")
                                        .typography(.displaySmall, design: .rounded)
                                    Text("Craft something brilliant today.")
                                        .typography(.titleMedium, color: primary.opacity(0.7), design: .rounded)
                                        .padding(.top, 4)
                                }
                                
                                Spacer()
                                
                                VStack(spacing: 3) {
                                    Image("resonanslogo.SFSymbol")
                                        .typography(.custom(size: 35, weight: .medium), color: primary)
                                    ZStack {
                                        Text(versionDisplayString)
                                            .typography(.caption, color: primary.opacity(0.4), design: .rounded)
                                    }
                                }
                            }
                            
                            Divider()
                            
                            GlassButton {
                                HapticsManager.shared.selection()
                                viewModel.selectedTab = .tools
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "magnifyingglass")
                                        .typography(.custom(size: 18, weight: .semibold))
                                    Text("Browse tools")
                                        .typography(.titleSmall, design: .rounded)
                                }
                                .overlay {
                                    HStack(spacing: 12) {
                                        Image(systemName: "magnifyingglass")
                                            .typography(.custom(size: 18, weight: .semibold))
                                        Text("Browse tools")
                                            .typography(.titleSmall, design: .rounded)
                                    }
                                    .shimmer(.init(tint: .white, highlight: .yellow, highlightOpacity: 0.75))
                                }
                                .foregroundStyle(accent.color)
                                .frame(maxWidth: .infinity)
                                .shadow(color: accent.color.opacity(colorScheme == .dark ? 0.25 : 0.2), radius: 16, x: 0, y: 10)
                                
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 4)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            if !favoriteTools.isEmpty {
                                VStack {
                                    HStack {
                                        Text("Favorites")
                                            .typography(.titleLarge, color: primary, design: .rounded)
                                        Spacer()
                                    }
                                    .padding(.horizontal, AppStyle.horizontalPadding)
                                    VStack(spacing: 12) {
                                        ForEach(favoriteTools) { tool in
                                            Button {
                                                HapticsManager.shared.selection()
                                                Task {
                                                    viewModel.selectedTab = .tools
                                                    if viewModel.selectedTool == nil {
                                                        viewModel.selectedTool = tool.id
                                                    } else {
                                                        viewModel.selectedTool = nil
                                                        try! await Task.sleep(for: .nanoseconds(1))
                                                        viewModel.selectedTool = tool.id
                                                    }
                                                }
                                            } label: {
                                                ToolOverview(tool: tool, presentedInHomeboard: true)
                                                    .environmentObject(viewModel)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal, AppStyle.horizontalPadding)
                                }
                                .animation(
                                    .spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.2),
                                    value: viewModel.favoriteToolIds
                                )
                            }
                            if !viewModel.recentTools.isEmpty {
                                VStack {
                                    HStack {
                                        Text("Recently used")
                                            .typography(.titleLarge, color: primary, design: .rounded)
                                        Spacer()
                                    }
                                    .padding(.horizontal, AppStyle.horizontalPadding)
                                    VStack(spacing: 12) {
                                        ForEach(viewModel.recentTools.reversed()) { tool in
                                            Button {
                                                HapticsManager.shared.selection()
                                                Task {
                                                    viewModel.selectedTab = .tools
                                                    if viewModel.selectedTool == nil {
                                                        viewModel.selectedTool = tool.id
                                                    } else {
                                                        viewModel.selectedTool = nil
                                                        try! await Task.sleep(for: .nanoseconds(1))
                                                        viewModel.selectedTool = tool.id
                                                    }
                                                }
                                            } label: {
                                                ToolOverview(tool: tool, presentedInHomeboard: true)
                                                    .environmentObject(viewModel)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal, AppStyle.horizontalPadding)
                                }
                                .animation(
                                    .spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.2),
                                    value: viewModel.favoriteToolIds
                                )
                            }
                            
                        }
                        
                        Spacer(minLength: 60)
                    }
                }
                .background(
                    LinearGradient(
                        colors: [accent.gradient, .clear],
                        startPoint: .topLeading,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )
                .navigationTitle("Home")
            }
        }
    }
    private func homeBox<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        AppCard{
            VStack(alignment: .leading, spacing: 16) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, AppStyle.horizontalPadding)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var trigger = false
        let tools = ToolManager.shared.tools
        var body: some View {
            HomeDashboardView(
                accent: .purple,
                primary: .black
            )
            .environmentObject(ContentViewModel())
        }
    }
    return PreviewWrapper()
}
