//
//  ToolOverview.swift
//  Resonans
import SwiftUI

struct ToolOverview: View {
    private let tool: ToolItem
    init(tool:  ToolItem, presentedInHomeboard atHome: Bool = false){
        self.tool = tool
        isHomeboard = atHome
    }
    
    private let isHomeboard: Bool
    
    @State private var showDetailView: Bool = false
    
    @EnvironmentObject private var viewModel: ContentViewModel
    
    @Namespace private var namespace
    
    var body: some View {
        Button(disableGlassEffect: true){
            viewModel.selectedTool = tool.id
        }label: {
            AppCard{
                HStack{
                    ToolIconView(tool: tool)
                    VStack(alignment: .leading){
                        Text(tool.title)
                            .typography(.titleMedium, color: .primary, design: .rounded)
                        
                        Text(tool.subtitle)
                            .typography(.caption, color: .secondary, design: .rounded)
                            .lineLimit(2)
                    }
                    .multilineTextAlignment(.leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationDestination(isPresented: Binding(get: {
            if isHomeboard{
                return false
            }else{
                return viewModel.selectedTool == tool.id
            }
        }, set: {
            if $0 {
                viewModel.selectedTool = tool.id
            }else{
                viewModel.selectedTool = nil
            }
        }), destination: {
            tool.destination
                .onAppear {
                viewModel.recentToolIDs.removeAll(where: { $0 == tool.id })
                viewModel.recentToolIDs.append(tool.id)
            }
        })
    }
}

#Preview {
    ToolOverview(tool: .audioExtractor)
}
