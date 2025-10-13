//
//  ToolOverview.swift
//  Resonans
import SwiftUI

struct ToolOverview: View {
    private let tool: ToolItem
    init(tool:  ToolItem){
        self.tool = tool
    }
    
    var body: some View {
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
            }
        }
    }
}

#Preview {
    ToolOverview(tool: .audioExtractor)
}
