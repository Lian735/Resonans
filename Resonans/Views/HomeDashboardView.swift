import SwiftUI

struct HomeDashboardView: View {
    let theme: AppTheme
    let favoriteTools: [ToolItem]
    let recentTools: [ToolItem]
    let allTools: [ToolItem]
    let onSelectTool: (ToolItem) -> Void
    let onShowAllTools: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                heroCard
                if !favoriteTools.isEmpty {
                    favoritesSection
                }
                recentsSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 28)
        }
        .background(theme.background.ignoresSafeArea())
    }

    private var heroCard: some View {
        SurfaceCard(theme: theme) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Welcome back")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.secondary)
                    Text("Create something brilliant")
                        .font(.title.weight(.heavy))
                        .foregroundStyle(theme.foreground)
                }

                Text("Resonans keeps your creative utilities in one focused workspace. Jump into tools or pick up where you left off.")
                    .font(.callout)
                    .foregroundStyle(theme.tertiary)

                Button(action: onShowAllTools) {
                    Label("Browse tools", systemImage: "wrench.and.screwdriver")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                .background(theme.buttonBackground)
                .foregroundStyle(theme.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private var favoritesSection: some View {
        SurfaceCard(theme: theme) {
            VStack(alignment: .leading, spacing: 16) {
                header(title: "Favourites", subtitle: "Pinned utilities ready to launch")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(favoriteTools) { tool in
                            ToolBadge(theme: theme, tool: tool) {
                                onSelectTool(tool)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var recentsSection: some View {
        SurfaceCard(theme: theme) {
            VStack(alignment: .leading, spacing: 16) {
                header(title: "Recently used", subtitle: "Quick access to your latest tools")

                if recentTools.isEmpty {
                    Text("Launch a tool to see it appear here.")
                        .font(.callout)
                        .foregroundStyle(theme.tertiary)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 12) {
                        ForEach(recentTools) { tool in
                            Button {
                                onSelectTool(tool)
                            } label: {
                                ToolRow(theme: theme, tool: tool)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if !recentTools.isEmpty && recentTools.count < allTools.count {
                    Button(action: onShowAllTools) {
                        Label("View all tools", systemImage: "arrow.right")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(theme.accentColor)
                    .padding(.top, 4)
                }
            }
        }
    }

    private func header(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(theme.foreground)
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(theme.secondary)
        }
    }
}

private struct ToolBadge: View {
    let theme: AppTheme
    let tool: ToolItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: tool.iconName)
                    .font(.title.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(18)
                    .background(
                        LinearGradient(
                            colors: tool.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(tool.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.foreground)
                    Text(tool.subtitle)
                        .font(.footnote)
                        .foregroundStyle(theme.tertiary)
                        .lineLimit(2)
                }
            }
            .frame(width: 180, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}

private struct ToolRow: View {
    let theme: AppTheme
    let tool: ToolItem

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: tool.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 54, height: 54)
                .overlay(
                    Image(systemName: tool.iconName)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(tool.title)
                    .font(.headline)
                    .foregroundStyle(theme.foreground)
                Text(tool.subtitle)
                    .font(.footnote)
                    .foregroundStyle(theme.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(theme.tertiary)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(theme.subtleSurface)
        )
    }
}

#Preview {
    HomeDashboardView(
        theme: AppTheme(accent: .purple, colorScheme: .light),
        favoriteTools: ToolItem.all,
        recentTools: ToolItem.all,
        allTools: ToolItem.all,
        onSelectTool: { _ in },
        onShowAllTools: {}
    )
}
