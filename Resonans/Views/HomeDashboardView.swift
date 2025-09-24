import SwiftUI

struct HomeDashboardView: View {
    let tools: [ToolItem]
    let favoriteTools: [ToolItem]
    let recentTools: [ToolItem]
    let newsItems: [AppNewsItem]
    @Binding var scrollToTopTrigger: Bool

    let accent: AccentColorOption
    let primary: Color
    let colorScheme: ColorScheme

    let onOpenTool: (ToolItem) -> Void
    let onToggleFavorite: (ToolItem.Identifier) -> Void
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

                    favoritesSection
                    recentsSection
                    newsSection

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

            Text("Pin your favourite workflows, hop into tools in one tap and keep an eye on what's new in Resonans.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(primary.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Button {
                    HapticsManager.shared.selection()
                    onShowTools()
                } label: {
                    Label("Browse tools", systemImage: "wrench.and.screwdriver")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 18)
                        .background(accent.color.opacity(colorScheme == .dark ? 0.3 : 0.15))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(accent.color.opacity(0.4), lineWidth: 1)
                        )
                        .foregroundStyle(accent.color)
                }
                .buttonStyle(.plain)

                Button {
                    HapticsManager.shared.selection()
                    if let firstFavorite = favoriteTools.first ?? tools.first {
                        onOpenTool(firstFavorite)
                    }
                } label: {
                    Label("Quick start", systemImage: "play.circle.fill")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 18)
                        .background(primary.opacity(AppStyle.cardFillOpacity))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(primary.opacity(AppStyle.strokeOpacity), lineWidth: 1)
                        )
                        .foregroundStyle(primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppStyle.innerPadding)
        .appCardStyle(primary: primary, colorScheme: colorScheme, shadowLevel: .large)
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Favorite tools")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(primary)
                Spacer()
                if !favoriteTools.isEmpty {
                    Text("Tap to toggle")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(primary.opacity(0.55))
                }
            }
            .padding(.horizontal, AppStyle.horizontalPadding)

            if tools.isEmpty {
                Text("No tools available yet.")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(primary.opacity(0.7))
                    .frame(maxWidth: .infinity)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(tools) { tool in
                            FavoriteToolChip(
                                tool: tool,
                                isFavorite: favoriteTools.contains(where: { $0.id == tool.id }),
                                primary: primary,
                                accent: accent.color,
                                colorScheme: colorScheme,
                                onToggle: { onToggleFavorite(tool.id) },
                                onOpen: { onOpenTool(tool) }
                            )
                        }
                    }
                    .padding(.horizontal, AppStyle.horizontalPadding)
                    .padding(.vertical, 6)
                }
            }
        }
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

    private var newsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("App news")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(primary)
                .padding(.horizontal, AppStyle.horizontalPadding)

            VStack(spacing: 16) {
                if newsItems.isEmpty {
                    Text("Fresh updates will appear here after our next release.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(primary.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                } else {
                    ForEach(newsItems) { news in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(news.formattedDate.uppercased())
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(primary.opacity(0.45))
                            Text(news.title)
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(primary)
                            Text(news.description)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(primary.opacity(0.7))
                        }
                        .padding(AppStyle.innerPadding)
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
            }
            .padding(.horizontal, AppStyle.horizontalPadding)
        }
    }
}

private struct FavoriteToolChip: View {
    let tool: ToolItem
    let isFavorite: Bool
    let primary: Color
    let accent: Color
    let colorScheme: ColorScheme
    let onToggle: () -> Void
    let onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                        .fill(LinearGradient(colors: tool.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 54, height: 54)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )
                    Image(systemName: tool.iconName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.35), radius: 6, x: 0, y: 2)
                }

                Spacer()

                Button(action: onToggle) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isFavorite ? accent : primary.opacity(0.6))
                }
                .buttonStyle(.plain)
            }

            Text(tool.title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(primary)
                .lineLimit(1)

            Text(tool.subtitle)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(primary.opacity(0.65))
                .lineLimit(2)

            Spacer(minLength: 4)

            Button {
                HapticsManager.shared.pulse()
                onOpen()
            } label: {
                Label("Launch", systemImage: "arrow.up.right.circle.fill")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(accent)
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .frame(width: 220, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                .fill(primary.opacity(AppStyle.cardFillOpacity))
                .overlay(
                    RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                        .stroke(primary.opacity(AppStyle.strokeOpacity), lineWidth: 1)
                )
        )
        .appShadow(colorScheme: colorScheme, level: .medium)
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
                favoriteTools: tools,
                recentTools: tools,
                newsItems: [
                    AppNewsItem(title: "Audio extractor gets waveform preview", description: "Drop a clip and preview the waveform before exporting to tune settings faster.", date: .now)
                ],
                scrollToTopTrigger: $trigger,
                accent: .purple,
                primary: .black,
                colorScheme: .light,
                onOpenTool: { _ in },
                onToggleFavorite: { _ in },
                onShowTools: {}
            )
        }
    }
    return PreviewWrapper()
}
