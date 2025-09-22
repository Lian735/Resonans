import SwiftUI

struct ToolsView: View {
    let tools: [ToolItem]
    @Binding var selectedTool: ToolItem.Identifier
    @Binding var scrollToTopTrigger: Bool
    @Binding var pendingLaunch: ToolItem.Identifier?

    let accent: AccentColorOption
    let primary: Color
    let colorScheme: ColorScheme
    let onSelect: (ToolItem, Bool) -> Void
    let onOpen: (ToolItem) -> Void

    @State private var showTopBorder = false
    @State private var navigationPath: [ToolItem.Identifier] = []

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 22) {
                        Color.clear
                            .frame(height: AppStyle.innerPadding)
                            .id("toolsTop")

                        ForEach(tools) { tool in
                            ToolCard(
                                tool: tool,
                                isSelected: tool.id == selectedTool,
                                primary: primary,
                                accent: accent.color,
                                colorScheme: colorScheme,
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
                                    launch(tool)
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
            .navigationDestination(for: ToolItem.Identifier.self) { identifier in
                if let tool = tools.first(where: { $0.id == identifier }) {
                    tool.destination()
                        .navigationTitle(tool.title)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbarColorScheme(colorScheme, for: .navigationBar)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(primary.opacity(0.7))
                        Text("Tool unavailable")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(primary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppStyle.background(for: colorScheme))
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onChange(of: pendingLaunch) { _, identifier in
            guard let identifier else { return }
            guard let tool = tools.first(where: { $0.id == identifier }) else { return }
            let isNewSelection = selectedTool != identifier
            if isNewSelection {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                    selectedTool = identifier
                }
            }
            onSelect(tool, isNewSelection)
            launch(tool)
            DispatchQueue.main.async {
                pendingLaunch = nil
            }
        }
    }

    private func launch(_ tool: ToolItem) {
        HapticsManager.shared.pulse()
        onOpen(tool)
        if navigationPath.last != tool.id {
            navigationPath.removeAll()
            navigationPath.append(tool.id)
        }
    }
}

private struct ToolCard: View {
    let tool: ToolItem
    let isSelected: Bool
    let primary: Color
    let accent: Color
    let colorScheme: ColorScheme
    let onSelect: () -> Void
    let onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
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
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(primary.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button(action: onOpen) {
                    Image(systemName: "arrow.up.right.circle.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(accent)
                        .padding(6)
                }
                .buttonStyle(.plain)
            }

            Divider()
                .overlay(primary.opacity(0.08))

            Text("Tap anywhere to set \(tool.title.lowercased()) as your active workspace.")
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
                        .strokeBorder(primary.opacity(isSelected ? 0.3 : AppStyle.strokeOpacity), lineWidth: isSelected ? 2 : 1)
                )
        )
        .contentShape(Rectangle())
        .appShadow(colorScheme: colorScheme, level: .medium, opacity: isSelected ? 0.55 : 0.4)
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                .strokeBorder(primary.opacity(isSelected ? 0.35 : 0), lineWidth: 3)
                .blur(radius: isSelected ? 0 : 6)
                .opacity(isSelected ? 1 : 0)
                .animation(.easeInOut(duration: 0.3), value: isSelected)
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
        @State private var trigger = false
        @State private var pending: ToolItem.Identifier?

        var body: some View {
            ToolsView(
                tools: ToolItem.all,
                selectedTool: $selected,
                scrollToTopTrigger: $trigger,
                pendingLaunch: $pending,
                accent: .purple,
                primary: .black,
                colorScheme: .light,
                onSelect: { _, _ in },
                onOpen: { _ in }
            )
        }
    }
    return PreviewWrapper()
}
