//
//  ToolOverview.swift
//  Resonans
import SwiftUI

struct ToolOverview: View {
    let tool: ToolItem

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: tool.iconName)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.accentColor)
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(tool.title)
                    .font(.headline)
                Text(tool.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

#Preview {
    ToolOverview(tool: ToolIdentifier.audioExtractor.tool)
}
