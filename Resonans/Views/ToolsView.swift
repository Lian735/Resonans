import SwiftUI

struct ToolsView: View {
    let tools: [ToolItem]
    @Binding var selectedTool: ToolItem.Identifier
    @Binding var scrollToTopTrigger: Bool

    let accent: AccentColorOption
    let primary: Color
    let colorScheme: ColorScheme
    let activeTool: ToolItem.Identifier?
    let onOpen: (ToolItem) -> Void
    let onClose: (ToolItem.Identifier) -> Void

    @State private var showTopBorder = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
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
                            onTap: {
                                if selectedTool != tool.id {
                                    withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                                        selectedTool = tool.id
                                    }
                                }
                                onOpen(tool)
                            },
                            onToggleOpenState: {
                                if activeTool == tool.id {
                                    onClose(tool.id)
                                } else {
                                    if selectedTool != tool.id {
                                        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                                            selectedTool = tool.id
                                        }
                                    }
                                    onOpen(tool)
                                }
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
        .background(
            .clear
        )
    }
}

private struct ToolListRow: View {
    let tool: ToolItem
    let primary: Color
    let colorScheme: ColorScheme
    let accent: Color
    let isSelected: Bool
    let isOpen: Bool
    let onTap: () -> Void
    let onToggleOpenState: () -> Void

    var body: some View {
        ToolRowCard(
            tool: tool,
            primary: primary,
            colorScheme: colorScheme,
            subtitleSpacing: 6,
            shadowOpacity: (isOpen || isSelected) ? 0.6 : 0.4
        ) {
            Button(action: {
                HapticsManager.shared.pulse()
                onToggleOpenState()
            }) {
                Image(systemName: isOpen ? "xmark" : "chevron.right")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(accent)
            }
            .buttonStyle(.plain)
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                .strokeBorder(
                    primary.opacity(
                        isOpen ? AppStyle.strokeOpacity * 1.8 : (isSelected ? AppStyle.strokeOpacity * 1.4 : AppStyle.strokeOpacity)
                    ),
                    lineWidth: isOpen ? 2 : 1
                )
                .opacity(isOpen || isSelected ? 1 : 0)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            HapticsManager.shared.selection()
            onTap()
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
                onOpen: { _ in },
                onClose: { _ in }
            )
        }
    }
    return PreviewWrapper()
}
