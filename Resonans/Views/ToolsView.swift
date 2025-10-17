import SwiftUI

struct ToolsView: View {
    let accent: AccentColorOption
    let primary: Color
    @Environment(\.colorScheme) private var colorScheme
    
    @EnvironmentObject private var viewModel: ContentViewModel
    
    @Namespace private var namespace
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 20) {
                ForEach(ToolItem.all) { tool in
                    ToolOverview(tool: tool)
                        .environmentObject(viewModel)
                }
            }
            .padding(.horizontal, AppStyle.horizontalPadding)
            .padding(.vertical, AppStyle.innerPadding)
        }
        .background(
            LinearGradient(
                colors: [accent.gradient, .clear],
                startPoint: .topLeading,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .scaledToFill()
        )
        .navigationTitle("Tools")
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarColorScheme(.automatic, for: .navigationBar)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selected: ToolItem.Identifier? = ToolItem.Identifier.audioExtractor
        @State private var trigger = false

        var body: some View {
            ToolsView(
                accent: .purple,
                primary: .black,
            )
        }
    }
    return PreviewWrapper()
}
