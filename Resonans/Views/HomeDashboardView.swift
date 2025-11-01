import SwiftUI

struct HomeDashboardView: View {

    @EnvironmentObject private var viewModel: ContentViewModel

    var body: some View {
        NavigationStack {
            List {
                welcomeSection
                recentSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Home")
        }
    }

    private var welcomeSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Welcome back")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("Craft something brilliant today")
                    .font(.title2.weight(.semibold))
            }

            Button {
                HapticsManager.shared.selection()
                viewModel.selectedTab = .tools
            } label: {
                Label("Browse tools", systemImage: "wrench.and.screwdriver")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var recentSection: some View {
        Section("Recently used") {
            if viewModel.recentTools.isEmpty {
                Text("Tools you open will appear here for quick access.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.recentTools.reversed()) { tool in
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
    }

    private func updateRecents(with identifier: ToolIdentifier) {
        viewModel.recentToolIDs.removeAll(where: { $0 == identifier })
        viewModel.recentToolIDs.append(identifier)
    }
}

#Preview {
    struct PreviewWrapper: View {
        var body: some View {
            HomeDashboardView()
                .environmentObject(ContentViewModel())
        }
    }
    return PreviewWrapper()
}
