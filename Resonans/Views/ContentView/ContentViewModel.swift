//
//  ContentViewModel.swift
//  Resonans
//
//  Created by Kevin Dallian on 10/10/25.
//

import Combine
import Foundation
import SwiftUI

final class ContentViewModel: ObservableObject {
    @Published var homeScrollTrigger: Bool = false
    @Published var toolsScrollTrigger: Bool = false
    @Published var settingsScrollTrigger: Bool = false
    @Published var showOnboarding: Bool = false
    
    @Published var selectedTab: TabSelection = .home
    @Published var selectedTool: ToolItem.Identifier? = nil

    var favoriteToolIds: Set<ToolItem.Identifier> = []
    var recentToolIDs: [ToolItem.Identifier] = []
    
    let tools = ToolItem.all
    let hapticsManager = HapticsManager.shared
    let cacheManager = CacheManager.shared
    
    var recentTools: [ToolItem] {
        recentToolIDs.compactMap { id in tools.first(where: { $0.id == id }) }
    }
    
    func closeActiveTool() {
        guard selectedTool != nil else { return }

        withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.85)) {
            selectedTool = nil
        }
    }

    func launchTool(_ tool: ToolItem) {
        updateRecentTools(with: tool.id)
        selectedTool = tool.id
    }
    
    func updateRecentTools(with identifier: ToolItem.Identifier) {
        recentToolIDs.removeAll(where: { $0 == identifier })
        recentToolIDs.insert(identifier, at: 0)
        if recentToolIDs.count > 6 {
            recentToolIDs = Array(recentToolIDs.prefix(6))
        }
        cacheManager.saveRecentTools(recentToolIDs)
    }
    
    func tabBarButtonAction(tab: TabSelection, trigger: Binding<Bool>) {
        if selectedTab == tab {
            trigger.wrappedValue.toggle()
        } else {
            selectedTab = tab
        }
    }
    
}

enum TabSelection: Hashable {
    case home
    case tools
    case settings
}
