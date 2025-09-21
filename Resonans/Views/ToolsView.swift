import SwiftUI

struct ToolsView: View {
    let tools: [ToolItem]
    @Binding var selectedTool: ToolItem.Identifier
    @Binding var scrollToTopTrigger: Bool

    let accent: AccentColorOption
    let primary: Color
    let colorScheme: ColorScheme
    let onSelect: (ToolItem, Bool) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    Color.clear
                        .frame(height: AppStyle.innerPadding)
                        .id("toolsTop")

                    ForEach(tools) { tool in
                        ToolCard(
                            tool: tool,
                            isSelected: tool.id == selectedTool,
                            primary: primary,
                            accent: accent.color,
                            colorScheme: colorScheme
                        ) {
                            let isNewSelection = selectedTool != tool.id
                            HapticsManager.shared.selection()
                            if isNewSelection {
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                                    selectedTool = tool.id
                                }
                            }
                            onSelect(tool, isNewSelection)
                        }
                    }

                    Spacer(minLength: 80)
                }
                .padding(.horizontal, AppStyle.horizontalPadding)
            }
            .coordinateSpace(name: "toolsScroll")
            .onChange(of: scrollToTopTrigger) { _, _ in
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                    proxy.scrollTo("toolsTop", anchor: .top)
                }
            }
        }
    }
}

private struct ToolCard: View {
    let tool: ToolItem
    let isSelected: Bool
    let primary: Color
    let accent: Color
    let colorScheme: ColorScheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center, spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                            .fill(LinearGradient(colors: tool.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 58, height: 58)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                            )
                        Image(systemName: tool.iconName)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(Color.white)
                            .shadow(color: Color.black.opacity(0.35), radius: 6, x: 0, y: 2)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(tool.title)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(primary)
                            .appTextShadow(colorScheme: colorScheme)

                        Text(tool.subtitle)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundStyle(primary.opacity(0.7))
                            .lineLimit(2)
                    }

                    Spacer()

                    if isSelected {
                        Label("Selected", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .labelStyle(.titleAndIcon)
                            .foregroundStyle(accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(accent.opacity(colorScheme == .dark ? 0.18 : 0.12))
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(accent.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                }

                Divider()
                    .overlay(primary.opacity(0.08))

                Text("Tap to configure and start using \(tool.title.lowercased()).")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(primary.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppStyle.innerPadding)
            .background(
                RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                    .fill(primary.opacity(AppStyle.cardFillOpacity))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                            .strokeBorder(primary.opacity(isSelected ? 0.28 : AppStyle.strokeOpacity), lineWidth: isSelected ? 2 : 1)
                    )
            )
            .contentShape(Rectangle())
            .appShadow(colorScheme: colorScheme, level: .medium, opacity: isSelected ? 0.55 : 0.4)
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                    .strokeBorder(primary.opacity(isSelected ? 0.38 : 0), lineWidth: 3)
                    .blur(radius: isSelected ? 0 : 6)
                    .opacity(isSelected ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3), value: isSelected)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: isSelected)
    }
}

#Preview {
    @State var selected = ToolItem.Identifier.audioExtractor
    @State var trigger = false
    return ToolsView(
        tools: ToolItem.all,
        selectedTool: $selected,
        scrollToTopTrigger: $trigger,
        accent: .purple,
        primary: .black,
        colorScheme: .light
    ) { _, _ in }
}
