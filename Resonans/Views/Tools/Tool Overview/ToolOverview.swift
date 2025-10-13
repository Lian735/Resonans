//
//  ToolOverview.swift
//  Resonans
import SwiftUI

struct ToolOverview: View {
    private let tool: ToolItem
    private let morphProgress: CGFloat

    init(tool:  ToolItem, morphProgress: CGFloat = 0){
        self.tool = tool
        self.morphProgress = morphProgress
    }

    var body: some View {
        AppCard{
            HStack{
                ToolIconView(tool: tool)
                VStack(alignment: .leading){
                    Text(tool.title)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .blur(radius: morphProgress * 6)
                        .opacity(max(0, 1 - morphProgress))

                    Text(tool.subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .blur(radius: morphProgress * 6)
                        .opacity(max(0, 1 - morphProgress))
                }
            }
        }
    }
}

#Preview {
    ToolOverview(tool: .audioExtractor)
}
