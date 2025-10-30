import SwiftUI

struct ToolsView: View {
    @EnvironmentObject private var viewModel: ContentViewModel

    var body: some View {
        NavigationStack {
            List {
                Section("Available tools") {
                    ForEach(viewModel.toolManager.tools) { tool in
                        NavigationLink {
                            tool.id.destination
                                .onAppear {
                                    updateRecents(with: tool.id)
                                }
                        } label: {
                            ToolOverview(tool: tool)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Tools")
        }
    }

    private func updateRecents(with identifier: ToolIdentifier) {
        viewModel.recentToolIDs.removeAll(where: { $0 == identifier })
        viewModel.recentToolIDs.append(identifier)
    }
}

#Preview {
    struct PreviewWrapper: View {
        var body: some View {
            ToolsView()
                .environmentObject(ContentViewModel())
        }
    }
    return PreviewWrapper()
}
