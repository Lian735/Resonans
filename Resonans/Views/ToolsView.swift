import SwiftUI

struct ToolsView: View {
    let tools: [ToolItem]
    @Binding var selectedTool: ToolItem.Identifier
    @Binding var activeTool: ToolItem.Identifier?
    @Binding var scrollToTopTrigger: Bool

    let accent: AccentColorOption
    let primary: Color
    let colorScheme: ColorScheme
    let onSelect: (ToolItem, Bool) -> Void
    let onOpen: (ToolItem) -> Void
    let onClose: (ToolItem.Identifier) -> Void

    @State private var showTopBorder = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 22) {
                    Color.clear
                        .frame(height: AppStyle.innerPadding)
                        .id("toolsTop")

                    VStack(spacing: 16) {
                        ForEach(tools) { tool in
                            ToolListRow(
                                tool: tool,
                                isSelected: tool.id == selectedTool,
                                isActive: tool.id == activeTool,
                                primary: primary,
                                accent: accent.color,
                                colorScheme: colorScheme,
                                onSelect: {
                                    select(tool)
                                },
                                onOpen: {
                                    select(tool)
                                    open(tool)
                                },
                                onClose: {
                                    close(tool)
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
                    }

                    Spacer(minLength: 80)
                }
                .padding(.horizontal, AppStyle.horizontalPadding)
            }
            .coordinateSpace(name: "toolsScroll")
            .background(AppStyle.background(for: colorScheme).ignoresSafeArea())
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
    }

    private func select(_ tool: ToolItem) {
        let isNewSelection = selectedTool != tool.id
        if isNewSelection {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                selectedTool = tool.id
            }
        }
        onSelect(tool, isNewSelection)
    }

    private func open(_ tool: ToolItem) {
        HapticsManager.shared.pulse()
        onOpen(tool)
    }

    private func close(_ tool: ToolItem) {
        HapticsManager.shared.selection()
        onClose(tool.id)
    }
}

private struct ToolListRow: View {
    let tool: ToolItem
    let isSelected: Bool
    let isActive: Bool
    let primary: Color
    let accent: Color
    let colorScheme: ColorScheme
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

            HStack(spacing: 12) {
                if isActive {
                    Button(action: onClose) {
                        Image(systemName: "xmark.square.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(accent)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }

                Button(action: onOpen) {
                    Image(systemName: "arrow.up.right.square.fill")
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
                        .stroke(primary.opacity(isSelected ? 0.28 : AppStyle.strokeOpacity), lineWidth: isSelected ? 2 : 1)
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous))
        .appShadow(colorScheme: colorScheme, level: .medium, opacity: isSelected ? 0.55 : 0.4)
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                .stroke(primary.opacity(isActive ? 0.35 : 0), lineWidth: 3)
                .blur(radius: isActive ? 0 : 6)
                .opacity(isActive ? 1 : 0)
                .animation(.easeInOut(duration: 0.3), value: isActive)
        )
        .onTapGesture {
            HapticsManager.shared.selection()
            onSelect()
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selected = ToolItem.Identifier.audioExtractor
        @State private var active: ToolItem.Identifier? = .audioExtractor
        @State private var trigger = false

        var body: some View {
            ToolsView(
                tools: ToolItem.all,
                selectedTool: $selected,
                activeTool: $active,
                scrollToTopTrigger: $trigger,
                accent: .purple,
                primary: .black,
                colorScheme: .light,
                onSelect: { _, _ in },
                onOpen: { _ in },
                onClose: { _ in }
            )
        }
    }
    return PreviewWrapper()
}
