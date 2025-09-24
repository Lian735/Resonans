import SwiftUI

struct ToolsView: View {
    let tools: [ToolItem]
    @Binding var selectedTool: ToolItem.Identifier
    @Binding var scrollToTopTrigger: Bool

    let accent: AccentColorOption
    let primary: Color
    let colorScheme: ColorScheme
    let activeTool: ToolItem.Identifier?
    let onSelect: (ToolItem, Bool) -> Void
    let onOpen: (ToolItem) -> Void
    let onClose: (ToolItem.Identifier) -> Void

    @State private var showTopBorder = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 18) {
                    Color.clear
                        .frame(height: AppStyle.innerPadding)
                        .id("toolsTop")

                    ForEach(tools) { tool in
                        ToolListRow(
                            tool: tool,
                            primary: primary,
                            colorScheme: colorScheme,
                            accent: accent.color,
                            isSelected: tool.id == selectedTool,
                            isOpen: activeTool == tool.id,
                            onSelect: {
                                let isNewSelection = selectedTool != tool.id
                                if isNewSelection {
                                    withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                                        selectedTool = tool.id
                                    }
                                }
                                onSelect(tool, isNewSelection)
                            },
                            onOpen: {
                                HapticsManager.shared.pulse()
                                onOpen(tool)
                            },
                            onClose: {
                                HapticsManager.shared.pulse()
                                onClose(tool.id)
                            }
                        )
                        .background(
                            GeometryReader { geo -> Color in
                                DispatchQueue.main.async {
                                    let shouldShow = geo.frame(in: .named("toolsScroll")).minY < -24
                                    if showTopBorder != shouldShow {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            showTopBorder = shouldShow
                                        }
                                    }
                                }
                                return Color.clear
                            }
                        )
                    }

                    Spacer(minLength: 80)
                }
                .padding(.horizontal, AppStyle.horizontalPadding)
            }
            .coordinateSpace(name: "toolsScroll")
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.gray.opacity(0.45))
                    .frame(height: 1)
                    .opacity(showTopBorder ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: showTopBorder)
            }
            .onChange(of: scrollToTopTrigger) { _, _ in
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                    proxy.scrollTo("toolsTop", anchor: .top)
                }
            }
        }
        .background(AppStyle.background(for: colorScheme))
    }
}

private struct ToolListRow: View {
    let tool: ToolItem
    let primary: Color
    let colorScheme: ColorScheme
    let accent: Color
    let isSelected: Bool
    let isOpen: Bool
    let onSelect: () -> Void
    let onOpen: () -> Void
    let onClose: () -> Void

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
                        .foregroundStyle(Color.white)
                )
                .appShadow(colorScheme: colorScheme, level: .small, opacity: 0.45)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(tool.title)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(primary)
                    if isOpen {
                        Text("OPEN")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(accent.opacity(0.15))
                            )
                    }
                }

                Text(tool.subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(primary.opacity(0.65))
                    .lineLimit(2)
            }

            Spacer()

            HStack(spacing: 12) {
                if isOpen {
                    Button(action: onClose) {
                        Image(systemName: "xmark.square.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(accent)
                    }
                    .buttonStyle(.plain)
                }

                Button(action: onOpen) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(accent)
                }
                .buttonStyle(.plain)
            }
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
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                .stroke(accent.opacity(isSelected ? 0.45 : 0), lineWidth: isSelected ? 2 : 0)
        )
        .appShadow(colorScheme: colorScheme, level: .medium, opacity: isSelected ? 0.55 : 0.4)
        .contentShape(Rectangle())
        .onTapGesture {
            HapticsManager.shared.selection()
            onSelect()
        }
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
                activeTool: nil,
                onSelect: { _, _ in },
                onOpen: { _ in },
                onClose: { _ in }
            )
        }
    }
    return PreviewWrapper()
}
