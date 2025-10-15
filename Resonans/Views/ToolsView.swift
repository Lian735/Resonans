import SwiftUI

struct ToolsView: View {
    let accent: AccentColorOption
    let primary: Color
    @Environment(\.colorScheme) private var colorScheme
    
    @Namespace private var namespace

    var body: some View {
        ScrollView{
            ForEach(ToolItem.all) { tool in
                ToolOverview(tool: tool)
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
    
    private var displayedTools: some View {
            ScrollView{
                ForEach(ToolItem.all) { tool in
                    NavigationLink{
                            tool.destination
                        .navigationTransition(.zoom(sourceID: "Button", in: namespace))
                    }label:{
                        AppCard{
                            HStack{
                                ToolIconView(tool: tool)
                                VStack(alignment: .leading){
                                    Text(tool.title)
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.primary)
                                    
                                    Text(tool.subtitle)
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                                .multilineTextAlignment(.leading)
                            }
                        }
                        .foregroundStyle(.primary)
                        .matchedTransitionSource(id: "Button", in: namespace)
                    }
                }
            }
            .background(
                LinearGradient(
                    colors: [accent.gradient, .clear],
                    startPoint: .topLeading,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
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
