import SwiftUI

struct ToolsView: View {
    let tools: [ToolItem]
    @Binding var selectedTool: ToolItem.Identifier?
    @Binding var scrollToTopTrigger: Bool

    let accent: AccentColorOption
    let primary: Color
    let colorScheme: ColorScheme
    let morphNamespace: Namespace.ID
    let overlayProgress: CGFloat
    let onOpen: (ToolItem) -> Void

    @State private var showTopBorder = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                VStack(spacing: 18) {
                    Color.clear
                        .frame(height: AppStyle.innerPadding)
                        .id("toolsTop")

                    ForEach(tools) { tool in
                        Button{
                            if selectedTool != tool.id {
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                                    selectedTool = tool.id
                                }
                            }
                            onOpen(tool)
                        } label: {
                            let isActive = selectedTool == tool.id
                            ToolOverview(tool: tool, morphProgress: isActive ? overlayProgress : 0)
                                .opacity(isActive ? max(0.0001, 1 - overlayProgress) : 1)
                                .matchedGeometryEffect(id: ToolMorphID.card(tool.id), in: morphNamespace)
                                .allowsHitTesting(!isActive)
                        }
                        .buttonStyle(.plain)
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

#Preview {
    struct PreviewWrapper: View {
        @State private var selected: ToolItem.Identifier? = ToolItem.Identifier.audioExtractor
        @State private var trigger = false
        @Namespace private var previewNamespace

        var body: some View {
            ToolsView(
                tools: ToolItem.all,
                selectedTool: $selected,
                scrollToTopTrigger: $trigger,
                accent: .purple,
                primary: .black,
                colorScheme: .light,
                morphNamespace: previewNamespace,
                overlayProgress: 0,
                onOpen: { _ in }
            )
        }
    }
    return PreviewWrapper()
}
