import SwiftUI

struct ToolsView: View {
    @EnvironmentObject private var viewModel: ContentViewModel

    var body: some View {
        List {
            Section("All tools") {
                ForEach(viewModel.toolManager.tools) { tool in
                    NavigationLink(value: tool.id) {
                        ToolListRow(tool: tool)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Tools")
    }
}

#Preview {
    ToolsView()
        .environmentObject(ContentViewModel())
}
