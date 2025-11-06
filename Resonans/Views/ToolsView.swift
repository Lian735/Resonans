import SwiftUI

struct ToolsView: View {
    let accent: AccentColorOption
    let primary: Color
    @Environment(\.colorScheme) private var colorScheme
    
    @EnvironmentObject private var viewModel: ContentViewModel
    
    @Namespace private var namespace
    
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack{
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    if #available(iOS 26, *){
                        GlassEffectContainer{
                            ForEach(viewModel.toolManager.tools.filter {
                                searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText)
                            }) { tool in
                                ToolOverview(tool: tool)
                                    .environmentObject(viewModel)
                            }
                        }
                    }else{
                        ForEach(viewModel.toolManager.tools.filter {
                            searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText)
                        }) { tool in
                            ToolOverview(tool: tool)
                                .environmentObject(viewModel)
                        }
                    }
                }
                .padding(.horizontal, AppStyle.horizontalPadding)
                .padding(.vertical, AppStyle.innerPadding)
            }
            .padding(.top, -AppStyle.innerPadding)
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
            .searchable(text: $searchText)
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selected: ToolIdentifier? = .audioExtractor
        @State private var trigger = false

        var body: some View {
            ToolsView(
                accent: .purple,
                primary: .black
            )
        }
    }
    return PreviewWrapper()
        .environmentObject(ContentViewModel())
}
