import SwiftUI

struct ToolListRow: View {
    let tool: ToolItem

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(tool.title)
                    .font(.headline)
                Text(tool.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: tool.iconName)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.accentColor)
                .frame(width: 28, height: 28)
        }
        .labelStyle(.toolLeadingIcon)
    }
}

private extension LabelStyle where Self == ToolLeadingIconLabelStyle {
    static var toolLeadingIcon: ToolLeadingIconLabelStyle { ToolLeadingIconLabelStyle() }
}

private struct ToolLeadingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top, spacing: 12) {
            configuration.icon
                .font(.title2)
            configuration.title
        }
    }
}

#Preview {
    ToolListRow(tool: .init(id: .bgRemover,
                            title: "Background Remover",
                            subtitle: "Remove backgrounds in seconds.",
                            iconName: "photo",
                            gradientHex: []))
}
