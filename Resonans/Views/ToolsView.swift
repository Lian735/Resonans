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
    let morphingToolID: ToolItem.Identifier?
    let morphProgress: CGFloat
    let onRequestMorph: (ToolItem, CGRect) -> Bool

    @State private var showTopBorder = false
    @State private var cardFrames: [ToolItem.Identifier: CGRect] = [:]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                VStack(spacing: 18) {
                    Color.clear
                        .frame(height: AppStyle.innerPadding)
                        .id("toolsTop")

                    ForEach(tools) { tool in
                        let isMorphing = morphingToolID == tool.id
                        Button {
                            guard morphingToolID == nil else { return }
                            let didStartMorph: Bool
                            if let frame = cardFrames[tool.id] {
                                didStartMorph = onRequestMorph(tool, frame)
                            } else {
                                didStartMorph = onRequestMorph(tool, .zero)
                            }

                            guard didStartMorph else { return }

                            if selectedTool != tool.id {
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                                    selectedTool = tool.id
                                }
                            }
                            onOpen(tool)
                        } label: {
                            ToolOverview(tool: tool, morphProgress: isMorphing ? morphProgress : 0)
                                .blur(radius: isMorphing ? morphProgress * 6 : 0)
                        }
                        .buttonStyle(.plain)
                        .disabled(isMorphing && morphProgress > 0.05)
                        .background(
                            GeometryReader { geo -> Color in
                                DispatchQueue.main.async {
                                    let localFrame = geo.frame(in: .named("toolsScroll"))
                                    let shouldShow = localFrame.minY < -24
                                    if showTopBorder != shouldShow {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            showTopBorder = shouldShow
                                        }
                                    }
                                    cardFrames[tool.id] = geo.frame(in: .global)
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
                onClose: { _ in },
                morphingToolID: nil,
                morphProgress: 0,
                onRequestMorph: { _, _ in true }
            )
        }
    }
    return PreviewWrapper()
}
