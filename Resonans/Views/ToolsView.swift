import SwiftUI

struct ToolsView: View {
    let tools: [ToolItem]
    let favorites: Set<ToolItem.Identifier>
    let accent: AccentColorOption
    let primary: Color
    let colorScheme: ColorScheme
    let onOpen: (ToolItem) -> Void
    let onToggleFavorite: (ToolItem.Identifier) -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                Text("Creative toolkit")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(primary)

                Text("Choose a tool to get started. Long-press a card to pin or unpin it from your favourites.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(primary.opacity(0.7))

                LazyVStack(spacing: 18) {
                    ForEach(tools) { tool in
                        ToolCard(
                            tool: tool,
                            layout: .large,
                            primary: primary,
                            colorScheme: colorScheme,
                            accent: accent.color,
                            isFavorite: favorites.contains(tool.id),
                            caption: "Open tool"
                        ) {
                            onOpen(tool)
                        }
                        .contextMenu {
                            Button {
                                HapticsManager.shared.selection()
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                    onToggleFavorite(tool.id)
                                }
                            } label: {
                                Label(
                                    favorites.contains(tool.id) ? "Remove from favourites" : "Add to favourites",
                                    systemImage: favorites.contains(tool.id) ? "heart.slash" : "heart"
                                )
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, AppStyle.horizontalPadding)
            .padding(.vertical, 24)
        }
        .scrollIndicators(.hidden)
    }
}

#Preview {
    struct PreviewWrapper: View {
        var body: some View {
            ToolsView(
                tools: ToolItem.all,
                favorites: [.audioExtractor],
                accent: .purple,
                primary: .black,
                colorScheme: .light,
                onOpen: { _ in },
                onToggleFavorite: { _ in }
            )
        }
    }
    return PreviewWrapper()
}
