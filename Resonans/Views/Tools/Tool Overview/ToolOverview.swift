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
        Button{
            showDetailView.toggle()
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
        }
        .matchedTransitionSource(id: "Button", in: namespace)
        .fullScreenCover(isPresented: $showDetailView, content: {
            NavigationStack{
                tool.destination
                    .toolbar(content: {
                        Button{
                            showDetailView.toggle()
                        }label:{
                            Label("Close", systemImage: "xmark")
                                .labelStyle(.iconOnly)
                        }
                    })
            }
            .navigationTransition(.zoom(sourceID: "Button", in: namespace))
        })
    }
}

#Preview {
    ToolOverview(tool: .audioExtractor)
}
