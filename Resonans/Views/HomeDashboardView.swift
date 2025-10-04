import SwiftUI

struct HomeDashboardView: View {
    let favorites: [ToolItem]
    let recents: [ToolItem]
    let accent: AccentColorOption
    let primary: Color
    let colorScheme: ColorScheme

    let onOpenTool: (ToolItem) -> Void
    let onShowTools: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                heroCard
                favoritesSection
                recentsSection
            }
            .padding(.vertical, 24)
            .padding(.bottom, 60)
            .padding(.horizontal, AppStyle.horizontalPadding)
        }
        .scrollIndicators(.hidden)
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Welcome back")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(primary.opacity(0.7))
                    Text("Shape your next sound")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(primary)
                }

                Spacer()

                Image(systemName: "sparkles")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(accent.color)
                    .shadow(color: accent.color.opacity(0.4), radius: 10, x: 0, y: 6)
            }

            Text("Every tool lives in one calm space. Start a new conversion or jump back into a recent session in just a tap.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(primary.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)

            Button {
                HapticsManager.shared.pulse()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                    onShowTools()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Browse tools")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(primary)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(accent.color.opacity(colorScheme == .dark ? 0.25 : 0.18))
                .clipShape(RoundedRectangle(cornerRadius: AppStyle.compactCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppStyle.compactCornerRadius, style: .continuous)
                        .stroke(accent.color.opacity(0.4), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(AppStyle.innerPadding)
        .appCardStyle(primary: primary, colorScheme: colorScheme, shadowLevel: .large)
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Pinned tools", subtitle: "Quick launch your favourites.")

            if favorites.isEmpty {
                Text("Pin tools during onboarding or from the tools list to keep them here for easy access.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(primary.opacity(0.65))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: AppStyle.compactCornerRadius, style: .continuous)
                            .fill(primary.opacity(AppStyle.subtleCardFillOpacity))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppStyle.compactCornerRadius, style: .continuous)
                                    .stroke(primary.opacity(AppStyle.strokeOpacity), lineWidth: 1)
                            )
                    )
                    .appShadow(colorScheme: colorScheme, level: .small, opacity: 0.35)
            } else {
                LazyVStack(spacing: 18) {
                    ForEach(favorites) { tool in
                        ToolCard(
                            tool: tool,
                            layout: .large,
                            primary: primary,
                            colorScheme: colorScheme,
                            accent: accent.color,
                            isFavorite: true,
                            caption: "Open tool"
                        ) {
                            onOpenTool(tool)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    private var recentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Recently opened", subtitle: "Pick up where you left off.")

            if recents.isEmpty {
                Text("Recent tools will show up here once you launch something.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(primary.opacity(0.65))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: AppStyle.compactCornerRadius, style: .continuous)
                            .fill(primary.opacity(AppStyle.subtleCardFillOpacity))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppStyle.compactCornerRadius, style: .continuous)
                                    .stroke(primary.opacity(AppStyle.strokeOpacity), lineWidth: 1)
                            )
                    )
                    .appShadow(colorScheme: colorScheme, level: .small, opacity: 0.3)
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(recents) { tool in
                        ToolCard(
                            tool: tool,
                            layout: .compact,
                            primary: primary,
                            colorScheme: colorScheme,
                            accent: accent.color,
                            isFavorite: favorites.contains(where: { $0.id == tool.id }),
                            caption: "Resume"
                        ) {
                            onOpenTool(tool)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(primary)
            Text(subtitle)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(primary.opacity(0.6))
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        var body: some View {
            HomeDashboardView(
                favorites: [ToolItem.audioExtractor],
                recents: [ToolItem.audioExtractor],
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
