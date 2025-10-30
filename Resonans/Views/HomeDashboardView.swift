import SwiftUI

struct HomeDashboardView: View {
    @EnvironmentObject private var viewModel: ContentViewModel

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome back")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Craft something brilliant today")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Button {
                        viewModel.selectedTab = .tools
                    } label: {
                        Label("Browse tools", systemImage: "wrench.and.screwdriver")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section("Recently used") {
                if viewModel.recentTools.isEmpty {
                    Text("Run any tool to see it here.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.recentTools.reversed()) { tool in
                        NavigationLink(value: tool.id) {
                            ToolListRow(tool: tool)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Home")
    }
}

#Preview {
    HomeDashboardView()
        .environmentObject(ContentViewModel())
}
