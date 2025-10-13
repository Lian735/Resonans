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
    @Published var showToolCloseIcon: Bool = false
    @Published var shouldSkipCloseReset: Bool = false
    
    var favoriteToolIds: Set<ToolItem.Identifier> = []
    var recentToolIDs: [ToolItem.Identifier] = []
    /// Used for tracking selectedTab before navigate to singluar tool tab
    var previousSelectedTab: TabSelection?
    
    let tools = ToolItem.all
    let hapticsManager = HapticsManager.shared
    let cacheManager = CacheManager.shared
    
    var recentTools: [ToolItem] {
        recentToolIDs.compactMap { id in tools.first(where: { $0.id == id }) }
    }
    
    func closeActiveTool() {
        guard let identifier = selectedTool else { return }
        let spring = Animation.spring(response: 0.45, dampingFraction: 0.8)

        withAnimation(spring) {
            showToolCloseIcon = false
            shouldSkipCloseReset = false

            if case let .tool(current) = selectedTab, current == identifier {
                selectedTab = previousSelectedTab ?? .home
            }

            selectedTool = nil
        }
    }
    
    func launchTool(_ tool: ToolItem) {
        updateRecentTools(with: tool.id)
        selectedTool = tool.id
        selectedTab = .tool(tool.id)
        showToolCloseIcon = false
        shouldSkipCloseReset = false
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
        let spring = Animation.spring(response: 0.45, dampingFraction: 0.8)
        if selectedTab == tab {
            trigger.wrappedValue.toggle()
        } else {
            selectedTab = tab
        }
        if showToolCloseIcon {
            withAnimation(spring) {
                showToolCloseIcon = false
            }
        }
        shouldSkipCloseReset = false
    }
    
    func toolButtonAction(isSelected: Bool, identifier: ToolItem.Identifier) {
        let spring = Animation.spring(response: 0.45, dampingFraction: 0.8)
        if isSelected {
            withAnimation(spring) {
                showToolCloseIcon = true
            }
            shouldSkipCloseReset = true
        } else {
            selectedTab = .tool(identifier)
            if showToolCloseIcon {
                hideToolCloseIcon()
            }
            shouldSkipCloseReset = false
        }
    }
    
    func hideToolCloseIcon() {
        guard showToolCloseIcon else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
            showToolCloseIcon = false
        }
    }
    
}

enum TabSelection: Hashable {
    case home
    case tools
    case settings
    case tool(ToolItem.Identifier)
}
