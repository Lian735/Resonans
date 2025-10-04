import SwiftUI

struct ToolsView: View {
    let theme: AppTheme
    let tools: [ToolItem]
    @Binding var favorites: Set<ToolItem.Identifier>
    let onSelectTool: (ToolItem) -> Void

    private var favoriteTools: [ToolItem] {
        tools.filter { favorites.contains($0.id) }
    }

    var body: some View {
        List {
            if !favoriteTools.isEmpty {
                Section("Favourites") {
                    ForEach(favoriteTools) { tool in
                        ToolRow(theme: theme, tool: tool, isFavourite: true) {
                            onSelectTool(tool)
                        } onToggleFavourite: {
                            toggleFavourite(tool.id)
                        }
                        .listRowBackground(theme.surface)
                    }
                }
                .textCase(nil)
            }

            Section("All tools") {
                ForEach(tools) { tool in
                    ToolRow(
                        theme: theme,
                        tool: tool,
                        isFavourite: favorites.contains(tool.id)
                    ) {
                        onSelectTool(tool)
                    } onToggleFavourite: {
                        toggleFavourite(tool.id)
                    }
                    .listRowBackground(theme.surface)
                }
            }
            .textCase(nil)
        }
        .listStyle(.insetGrouped)
        .listRowSeparator(.hidden)
        .environment(\.defaultMinListRowHeight, 68)
        .scrollContentBackground(.hidden)
        .background(theme.background)
    }

    private func toggleFavourite(_ identifier: ToolItem.Identifier) {
        if favorites.contains(identifier) {
            favorites.remove(identifier)
        } else {
            favorites.insert(identifier)
        }
        HapticsManager.shared.selection()
    }
}

private struct ToolRow: View {
    let theme: AppTheme
    let tool: ToolItem
    let isFavourite: Bool
    let onSelect: () -> Void
    let onToggleFavourite: () -> Void

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
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: tool.iconName)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(tool.title)
                    .font(.headline)
                    .foregroundStyle(theme.foreground)
                Text(tool.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(theme.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Button(action: onToggleFavourite) {
                Image(systemName: isFavourite ? "heart.fill" : "heart")
                    .foregroundStyle(isFavourite ? theme.accentColor : theme.tertiary)
            }
            .buttonStyle(.plain)

            Image(systemName: "arrow.up.right.square")
                .foregroundStyle(theme.accentColor)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var favourites: Set<ToolItem.Identifier> = [.audioExtractor]

        var body: some View {
            NavigationStack {
                ToolsView(
                    theme: AppTheme(accent: .purple, colorScheme: .light),
                    tools: ToolItem.all,
                    favorites: $favourites,
                    onSelectTool: { _ in }
                )
            }
        }
    }

    return PreviewWrapper()
}
