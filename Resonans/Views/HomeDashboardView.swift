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
                    AppCard{
                        VStack(alignment: .leading, spacing: 20) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Welcome back!")
                                        .typography(.displaySmall, design: .rounded)
                                    Text("Craft something brilliant today.")
                                        .typography(.titleMedium, color: primary.opacity(0.7), design: .rounded)
                                }
                                
                                Spacer()
                                
                                VStack(spacing: 3) {
                                    Image("resonansicon.SFSymbol")
                                        .typography(.custom(size: 35, weight: .medium), color: primary.opacity(0.6))
                                        .overlay {
                                            GeometryReader { proxy in
                                                let width = proxy.size.width
                                                let height = proxy.size.height
                                                let oversize: CGFloat = 1.8
                                                let overlayWidth = width * oversize
                                                let overlayHeight = height * oversize

                                                LinearGradient(
                                                    colors: [
                                                        .clear,
                                                        Color.white.opacity(colorScheme == .dark ? 0.35 : 0.4),
                                                        .clear
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                                .frame(width: overlayWidth, height: overlayHeight)
                                                .rotationEffect(.degrees(20))
                                                .offset(x: shimmerPhase ? overlayWidth : -overlayWidth)
                                                .blendMode(.plusLighter)
                                                .animation(
                                                    .easeInOut(duration: 2.2)
                                                        .delay(0.6)
                                                        .repeatForever(autoreverses: false),
                                                    value: shimmerPhase
                                                )
                                                .mask(
                                                    Image("resonansicon.SFSymbol")
                                                        .typography(.custom(size: 35, weight: .medium), color: primary.opacity(0.6))
                                                )
                                                .frame(width: width, height: height, alignment: .center)
                                                .clipped()
                                            }
                                        }
                                        .onAppear {
                                            shimmerPhase = true
                                        }
                                    ZStack {
                                        Text(versionDisplayString)
                                            .typography(.caption, color: primary.opacity(0.4), design: .rounded)
                                    }
                                }
                            }
                            
                            Button {
                                HapticsManager.shared.selection()
                                viewModel.selectedTab = .tools
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "wrench.and.screwdriver")
                                        .typography(.custom(size: 18, weight: .semibold))
                                    Text("Browse tools")
                                        .typography(.titleSmall, design: .rounded)
                                }
                                .foregroundStyle(accent.color)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                                        .fill(accent.color.opacity(colorScheme == .dark ? 0.28 : 0.2))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                                        .stroke(accent.color.opacity(0.35), lineWidth: 1)
                                )
                                .shadow(color: accent.color.opacity(colorScheme == .dark ? 0.25 : 0.2), radius: 16, x: 0, y: 10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                        .padding(.horizontal, AppStyle.horizontalPadding)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recently used")
                                .typography(.titleLarge, color: primary, design: .rounded)
                            Spacer()
                        }
                        .padding(.horizontal, AppStyle.horizontalPadding)

                        if viewModel.recentTools.isEmpty {
                            AppCard{
                                Text("Jump back into tools and your history will live here.")
                                    .typography(.body, color: primary.opacity(0.65), design: .rounded)
                                    .frame(maxWidth: .infinity)
                            }
                            .padding(.horizontal, AppStyle.horizontalPadding)
                        } else {
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
