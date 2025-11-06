import SwiftUI

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
    
    var body: some View {
        NavigationStack{
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 28) {
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
                                Image("resonansicon.SFSymbol")
                                    .typography(.custom(size: 35, weight: .medium), color: primary)
                                ZStack {
                                    Text(versionDisplayString)
                                        .typography(.caption, color: primary.opacity(0.4), design: .rounded)
                                }
                            }
                        }
                        
                        Divider()
                        
                        Button {
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
                        if !viewModel.recentTools.isEmpty {
                            HStack {
                                Text("Recently used")
                                    .typography(.titleLarge, color: primary, design: .rounded)
                                Spacer()
                            }
                            .padding(.horizontal, AppStyle.horizontalPadding)
                            VStack(spacing: 12) {
                                ForEach(viewModel.recentTools.reversed()) { tool in
                                    Button(disableGlassEffect: true){
                                        HapticsManager.shared.selection()
                                        Task{
                                            viewModel.selectedTab = .tools
                                            if viewModel.selectedTool == nil{
                                                viewModel.selectedTool = tool.id
                                            }else{
                                                viewModel.selectedTool = nil
                                                try! await Task.sleep(for: .nanoseconds(1))
                                                viewModel.selectedTool = tool.id
                                            }
                                        }
                                    } label: {
                                        ToolOverview(tool: tool, presentedInHomeboard: true)
                                            .environmentObject(viewModel)
                                            .disabled(true)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, AppStyle.horizontalPadding)
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
        }
    }
    return PreviewWrapper()
}
