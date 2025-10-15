//
//  ToolOverview.swift
//  Resonans
import SwiftUI

struct ToolOverview: View {
    private let tool: ToolItem
    init(tool:  ToolItem){
        self.tool = tool
    }
    
    @State private var showDetailView: Bool = false
    
    @Namespace private var namespace
    
    var body: some View {
        NavigationLink{
                tool.destination
                .navigationTransition(.zoom(sourceID: tool.id, in: namespace))
        }label:{
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
                    .multilineTextAlignment(.leading)
                }
            }
            .foregroundStyle(.primary)
            .matchedTransitionSource(id: tool.id, in: namespace)
        }
    }
}

#Preview {
    ToolOverview(tool: .audioExtractor)
}
