import SwiftUI

struct HomeDashboardView: View {

    let accent: AccentColorOption
    let primary: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    @EnvironmentObject private var viewModel: ContentViewModel
    
    var body: some View {
        NavigationStack{
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 28) {
                    AppCard{
                        VStack(alignment: .leading, spacing: 20) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Welcome back")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundStyle(primary.opacity(0.7))
                                    Text("Craft something brilliant today")
                                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                                        .foregroundStyle(primary)
                                }
                                
                                Spacer()
                                
                                VStack(spacing: 8) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 26, weight: .bold))
                                        .foregroundStyle(accent.color)
                                    Text("v1.2")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundStyle(primary.opacity(0.6))
                                }
                            }
                            
                            Button {
                                HapticsManager.shared.selection()
                                viewModel.selectedTab = .tools
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "wrench.and.screwdriver")
                                        .font(.system(size: 18, weight: .semibold))
                                    Text("Browse tools")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                }
                                .foregroundStyle(accent.color)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(accent.color.opacity(colorScheme == .dark ? 0.28 : 0.18))
                                .clipShape(RoundedRectangle(cornerRadius: AppStyle.compactCornerRadius, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppStyle.compactCornerRadius, style: .continuous)
                                        .stroke(accent.color.opacity(0.35), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(AppStyle.innerPadding)
                    }
                        .padding(.horizontal, AppStyle.horizontalPadding)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recently used")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(primary)
                            Spacer()
                        }
                        .padding(.horizontal, AppStyle.horizontalPadding)

                        if viewModel.recentTools.isEmpty {
                            AppCard{
                                Text("Jump back into tools and your history will live here.")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundStyle(primary.opacity(0.65))
                                    .frame(maxWidth: .infinity)
                            }
                            .padding(.horizontal, AppStyle.horizontalPadding)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(viewModel.recentTools.reversed()) { tool in
                                    Button {
                                        HapticsManager.shared.selection()
                                        viewModel.selectedTab = .tools
                                        viewModel.selectedTool = tool.id
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
        let tools = ToolItem.all
        var body: some View {
            HomeDashboardView(
                accent: .purple,
                primary: .black,
            )
        }
    }
    return PreviewWrapper()
}
