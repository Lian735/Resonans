import SwiftUI

struct ToolsView: View {
    let accent: AccentColorOption
    let primary: Color
    @Environment(\.colorScheme) private var colorScheme
    
    @EnvironmentObject private var viewModel: ContentViewModel
    
    @Namespace private var namespace
    
    var body: some View {
        ScrollView{
            ForEach(ToolItem.all) { tool in
                ToolOverview(tool: tool)
                    .environmentObject(viewModel)
            }
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
