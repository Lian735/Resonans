//
//  ToolOverview.swift
//  Resonans
import SwiftUI

struct ToolOverview: View {
    private let tool: ToolItem
    private let morphProgress: CGFloat

    init(tool: ToolItem, morphProgress: CGFloat = 0) {
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
                        .opacity(textOpacity)
                        .blur(radius: textBlur)

                    Text(tool.subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .opacity(textOpacity)
                        .blur(radius: textBlur)
                }
            }
        }
        .opacity(cardOpacity)
    }

    private var textOpacity: CGFloat {
        max(0, 1 - morphProgress * 1.2)
    }

    private var textBlur: CGFloat {
        morphProgress * 8
    }

    private var cardOpacity: Double {
        Double(max(0, 1 - morphProgress))
    }
}

#Preview {
    ToolOverview(tool: .audioExtractor)
}
