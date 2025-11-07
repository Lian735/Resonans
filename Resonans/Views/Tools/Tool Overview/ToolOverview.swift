//
//  ToolOverview.swift
//  Resonans
import SwiftUI

struct ToolOverview: View {
    private let tool: ToolItem
    init(tool:  ToolItem, presentedInHomeboard atHome: Bool = false){
        self.tool = tool
        self.isHomeboard = atHome
        // Seed favorite state from persisted storage or model default
        let key = "favorite_\(tool.id.rawValue)"
        let stored = UserDefaults.standard.object(forKey: key) as? Bool
        _isFavorite = State(initialValue: stored ?? false)
    }
    
    private let isHomeboard: Bool
    
    @State private var showDetailView: Bool = false
    @State private var isFavorite: Bool = false
    
    @EnvironmentObject private var viewModel: ContentViewModel
    
    @Namespace private var namespace
    
    var body: some View {
        GlassButton(disableGlassEffect: true){
            HapticsManager.shared.selection()
            viewModel.selectedTool = tool.id
        }label: {
            AppCard{
                HStack{
                    ToolIconView(tool: tool)
                    HStack {
                        VStack(alignment: .leading){
                            Text(tool.title)
                                .typography(.titleMedium, color: .primary, design: .rounded)
                            Text(tool.subtitle)
                                .typography(.caption, color: .secondary, design: .rounded)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxHeight: 52, alignment: .top)
                        .multilineTextAlignment(.leading)
                        Spacer()
                        VStack(alignment: .trailing) {
                            Button {
                                let key = "favorite_\(tool.id.rawValue)"
                                if isFavorite {
                                    // turning off
                                    isFavorite = false
                                    UserDefaults.standard.set(false, forKey: key)
                                    viewModel.favoriteToolIds.remove(tool.id)
                                } else {
                                    // turning on
                                    isFavorite = true
                                    UserDefaults.standard.set(true, forKey: key)
                                    viewModel.favoriteToolIds.insert(tool.id)
                                }
                                HapticsManager.shared.selection()
                            } label: {
                                Image(systemName: isFavorite ? "star.fill" : "star")
                                    .foregroundStyle(isFavorite ? .yellow : Color(.gray))
                            }
                                 
                            Spacer()
                            
                            if tool.beta {
                                betaBadge
                            }
                        }
                        .frame(maxHeight: 52, alignment: .center)
                    }
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
            tool.id.destination
                .onAppear {
                viewModel.recentToolIDs.removeAll(where: { $0 == tool.id })
                viewModel.recentToolIDs.append(tool.id)
            }
        })
        .onAppear {
            let key = "favorite_\(tool.id.rawValue)"
            let stored = UserDefaults.standard.object(forKey: key) as? Bool
            let envFav = viewModel.favoriteToolIds.contains(tool.id)
            // prefer env set; fall back to stored if env not set
            isFavorite = envFav || (stored ?? false)
            if isFavorite && !envFav {
                viewModel.favoriteToolIds.insert(tool.id)
            }
        }
    }
}

var betaBadge: some View {
    Text("BETA")
        .typography(.caption, color: .white, design: .rounded)
        .fontWeight(.bold)
        .padding(.vertical, 2)
        .padding(.horizontal, 6)
        .background(
            GeometryReader { proxy in
                let size = proxy.size
                // Animated MeshGradient background clipped to capsule
                AnimatedMeshGradient()
                    .frame(width: size.width, height: size.height)
                    .clipShape(Capsule(style: .circular))
                    .overlay(
                        Capsule(style: .circular)
                            .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                    )
            }
        )
}

#Preview {
    ToolOverview(tool: ToolIdentifier.editor.tool)
        .environmentObject(ContentViewModel())
}
