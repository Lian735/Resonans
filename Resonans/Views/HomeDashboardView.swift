import SwiftUI

struct HomeDashboardView: View {
    let tools: [ToolItem]
    let recentTools: [ToolItem]
    @Binding var scrollToTopTrigger: Bool

    let accent: AccentColorOption
    let primary: Color
    let colorScheme: ColorScheme

    let onOpenTool: (ToolItem) -> Void
    let onShowTools: () -> Void

    @State private var showTopBorder = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 28) {
                    Color.clear
                        .frame(height: AppStyle.innerPadding)
                        .padding(.bottom, -24)
                        .id("homeTop")

                    heroCard
                        .background(
                            GeometryReader { geo -> Color in
                                DispatchQueue.main.async {
                                    let shouldShow = geo.frame(in: .named("homeScroll")).minY < 0
                                    if showTopBorder != shouldShow {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            showTopBorder = shouldShow
                                        }
                                    }
                                }
                                return Color.clear
                            }
                        )
                        .padding(.horizontal, AppStyle.horizontalPadding)

                    recentsSection

                    Spacer(minLength: 60)
                }
            }
            .coordinateSpace(name: "homeScroll")
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.gray.opacity(0.45))
                    .frame(height: 1)
                    .opacity(showTopBorder ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: showTopBorder)
            }
            .onChange(of: scrollToTopTrigger) { _, _ in
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                    proxy.scrollTo("homeTop", anchor: .top)
                }
            }
        }
    }

    private var heroCard: some View {
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
                onShowTools()
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
        .appCardStyle(primary: primary, colorScheme: colorScheme, shadowLevel: .large)
    }

    private var recentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recently used")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(primary)
                Spacer()
            }
            .padding(.horizontal, AppStyle.horizontalPadding)

            if recentTools.isEmpty {
                Text("Jump back into tools and your history will live here.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(primary.opacity(0.65))
                    .padding(.horizontal, AppStyle.horizontalPadding)
                    .padding(.vertical, 28)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                            .fill(primary.opacity(AppStyle.subtleCardFillOpacity))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                                    .stroke(primary.opacity(AppStyle.strokeOpacity), lineWidth: 1)
                            )
                    )
                    .appShadow(colorScheme: colorScheme, level: .medium)
                    .padding(.horizontal, AppStyle.horizontalPadding)
            } else {
                VStack(spacing: 12) {
                    ForEach(recentTools) { tool in
                        Button {
                            HapticsManager.shared.selection()
                            onOpenTool(tool)
                        } label: {
                            ToolHistoryRow(tool: tool, primary: primary, colorScheme: colorScheme)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppStyle.horizontalPadding)
            }
        }
    }
}

private struct ToolHistoryRow: View {
    let tool: ToolItem
    let primary: Color
    let colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                .fill(LinearGradient(colors: tool.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 52, height: 52)
                .overlay(
                    RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
                .overlay(
                    Image(systemName: tool.iconName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                )
                .appShadow(colorScheme: colorScheme, level: .small, opacity: 0.45)

            VStack(alignment: .leading, spacing: 4) {
                Text(tool.title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(primary)
                Text(tool.subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(primary.opacity(0.65))
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(primary.opacity(0.4))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                .fill(primary.opacity(AppStyle.cardFillOpacity))
                .overlay(
                    RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                        .stroke(primary.opacity(AppStyle.strokeOpacity), lineWidth: 1)
                )
        )
        .appShadow(colorScheme: colorScheme, level: .small)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var trigger = false
        let tools = ToolItem.all
        var body: some View {
            HomeDashboardView(
                tools: tools,
                recentTools: tools,
                scrollToTopTrigger: $trigger,
                accent: .purple,
                primary: .black,
                colorScheme: .light,
                onOpenTool: { _ in },
                onShowTools: {}
            )
        }
    }
    return PreviewWrapper()
}
