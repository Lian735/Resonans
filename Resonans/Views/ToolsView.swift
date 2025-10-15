import SwiftUI

struct ToolsView: View {
    let tools: [ToolItem]
    @Binding var selectedTool: ToolItem.Identifier?
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
                    if #available(iOS 26, *) {
                        GlassEffectContainer {
                            toolsView(tools: tools)
                        }
                    } else {
                        toolsView(tools: tools)
                    }
                    Spacer(minLength: 80)
                }
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
    
    @ViewBuilder
    private func toolsView(tools: [ToolItem]) -> some View {
        ForEach(tools) { tool in
            ToolOverview(tool: tool)
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
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selected: ToolItem.Identifier? = ToolItem.Identifier.audioExtractor
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
