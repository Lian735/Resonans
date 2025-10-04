import SwiftUI

struct HomeDashboardView: View {
    let favoriteTools: [ToolItem]
    let recentTools: [ToolItem]
    @Binding var scrollToTopTrigger: Bool

    let accent: AccentColorOption
    let primary: Color
    let colorScheme: ColorScheme

    let onOpenTool: (ToolItem) -> Void
    let onShowTools: () -> Void

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 28) {
                    Color.clear
                        .frame(height: 1)
                        .id("home-top")

                    heroCard
                        .transition(.opacity.combined(with: .scale))

                    if !favoriteTools.isEmpty {
                        favoritesSection
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    recentsSection
                        .transition(.move(edge: .bottom).combined(with: .opacity))

                    Spacer(minLength: 60)
                }
                .padding(.horizontal, AppStyle.horizontalPadding)
                .padding(.vertical, 32)
            }
            .onChange(of: scrollToTopTrigger) { _, _ in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    proxy.scrollTo("home-top", anchor: .top)
                }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: favoriteTools.count)
        .animation(.easeInOut(duration: 0.35), value: recentTools.count)
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Welcome back")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(primary.opacity(0.7))
                    Text("Craft something brilliant today")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
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
                Label("Browse tools", systemImage: "wrench.and.screwdriver")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: AppStyle.compactCornerRadius, style: .continuous)
                            .fill(accent.color.opacity(colorScheme == .dark ? 0.25 : 0.15))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(AppStyle.innerPadding)
        .appCardStyle(primary: primary, colorScheme: colorScheme, shadowLevel: .large)
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Pinned favourites", icon: "heart.fill")

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(favoriteTools) { tool in
                    Button {
                        onOpenTool(tool)
                    } label: {
                        ToolTile(
                            tool: tool,
                            accent: accent.color,
                            primary: primary,
                            colorScheme: colorScheme,
                            isHighlighted: false,
                            isFavorite: true
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var recentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Recently opened", icon: "clock.fill")

            if recentTools.isEmpty {
                Text("Open a tool and it’ll show up here for quick access.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(primary.opacity(0.65))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 32)
                    .padding(.horizontal, 18)
                    .appCardStyle(primary: primary, colorScheme: colorScheme, shadowLevel: .medium)
            } else {
                VStack(spacing: 12) {
                    ForEach(recentTools) { tool in
                        Button {
                            onOpenTool(tool)
                        } label: {
                            ToolTile(
                                tool: tool,
                                accent: accent.color,
                                primary: primary,
                                colorScheme: colorScheme,
                                isHighlighted: false,
                                isFavorite: favoriteTools.contains(where: { $0.id == tool.id })
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(accent.color)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(accent.color.opacity(colorScheme == .dark ? 0.26 : 0.16))
                )
            Text(title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(primary)
            Spacer()
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var trigger = false
        var body: some View {
            HomeDashboardView(
                favoriteTools: ToolItem.all,
                recentTools: ToolItem.all,
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
