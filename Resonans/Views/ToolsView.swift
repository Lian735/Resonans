import SwiftUI

struct ToolsView: View {
    let tools: [ToolItem]
    @Binding var selectedTool: ToolItem.Identifier
    @Binding var scrollToTopTrigger: Bool

    let accent: AccentColorOption
    let primary: Color
    let colorScheme: ColorScheme
    let favorites: Set<ToolItem.Identifier>
    let onOpen: (ToolItem) -> Void

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 18) {
                    Color.clear
                        .frame(height: 1)
                        .gridCellColumns(columns.count)
                        .id("tools-top")

                    ForEach(tools) { tool in
                        Button {
                            handleSelection(for: tool)
                        } label: {
                            ToolTile(
                                tool: tool,
                                accent: accent.color,
                                primary: primary,
                                colorScheme: colorScheme,
                                isHighlighted: selectedTool == tool.id,
                                isFavorite: favorites.contains(tool.id)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppStyle.horizontalPadding)
                .padding(.vertical, 28)
            }
            .onChange(of: scrollToTopTrigger) { _, _ in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    proxy.scrollTo("tools-top", anchor: .top)
                }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: selectedTool)
    }

    private func handleSelection(for tool: ToolItem) {
        if selectedTool != tool.id {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                selectedTool = tool.id
            }
        }
        HapticsManager.shared.selection()
        onOpen(tool)
    }
}

struct ToolTile: View {
    let tool: ToolItem
    let accent: Color
    let primary: Color
    let colorScheme: ColorScheme
    let isHighlighted: Bool
    let isFavorite: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                    .fill(LinearGradient(colors: tool.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 50, height: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
                    .overlay(
                        Image(systemName: tool.iconName)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.6 : 0.15), radius: 12, x: 0, y: 8)

                Spacer()

                if isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(accent)
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(accent.opacity(colorScheme == .dark ? 0.25 : 0.15))
                        )
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(tool.title)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(primary)
                Text(tool.subtitle)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(primary.opacity(0.65))
                    .lineLimit(2)
            }

            HStack(spacing: 6) {
                Text("Open")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundStyle(accent)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                .fill(primary.opacity(AppStyle.cardFillOpacity))
                .overlay(
                    RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                        .stroke(primary.opacity(AppStyle.strokeOpacity), lineWidth: 1)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                .stroke(accent.opacity(isHighlighted ? 0.6 : 0), lineWidth: isHighlighted ? 2 : 0)
        )
        .shadow(
            color: AppStyle.shadowColor(for: colorScheme).opacity(isHighlighted ? 0.55 : 0.35),
            radius: isHighlighted ? 24 : 18,
            x: 0,
            y: isHighlighted ? 16 : 12
        )
        .scaleEffect(isHighlighted ? 1.02 : 1)
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: isHighlighted)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selected = ToolItem.Identifier.audioExtractor
        @State private var trigger = false

        var body: some View {
            ToolsView(
                tools: ToolItem.all,
                selectedTool: $selected,
                scrollToTopTrigger: $trigger,
                accent: .purple,
                primary: .black,
                colorScheme: .light,
                favorites: Set([ToolItem.Identifier.audioExtractor]),
                onOpen: { _ in }
            )
        }
    }
    return PreviewWrapper()
}
