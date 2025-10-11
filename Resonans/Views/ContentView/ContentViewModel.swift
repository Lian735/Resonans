//
//  ContentViewModel.swift
//  Resonans
//
//  Created by Kevin Dallian on 10/10/25.
//

import Foundation

final class ContentViewModel: ObservableObject {
    @Published var homeScrollTrigger: Bool = false
    @Published var toolsScrollTrigger: Bool = false
    @Published var settingsScrollTrigger: Bool = false
    @Published var showOnboarding: Bool = false
    
    @Published var selectedTab: TabSelection = .home
    @Published var selectedTool: ToolItem.Identifier? = nil
    var favoriteToolIds: Set<ToolItem.Identifier> = []
    var recentToolIDs: [ToolItem.Identifier] = []
    /// Used for tracking selectedTab before navigate to singluar tool tab
    var previousSelectedTab: TabSelection?
    
    let tools = ToolItem.all
    var recentTools: [ToolItem] {
        recentToolIDs.compactMap { id in tools.first(where: { $0.id == id }) }
    }
    
}

enum TabSelection: Hashable {
    case home
    case tools
    case settings
    case tool(ToolItem.Identifier)
}
