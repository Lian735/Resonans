import SwiftUI

struct ToolDestinationView: View {
    let toolIdentifier: ToolIdentifier
    @EnvironmentObject private var viewModel: ContentViewModel

    var body: some View {
        toolIdentifier.destination
            .onAppear {
                viewModel.recentToolIDs.removeAll { $0 == toolIdentifier }
                viewModel.recentToolIDs.append(toolIdentifier)
            }
    }
}
