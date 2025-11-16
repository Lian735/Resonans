//
//  ContentViewModel.swift
//  Resonans
//
//  Created by Kevin Dallian on 10/10/25.
//

import Combine
import Foundation
import SwiftUI

@MainActor
/// Shared view model powering the root tab view and onboarding state.
final class ContentViewModel: ObservableObject {
    @Published var showOnboarding: Bool = false
    
    @Published var selectedTab: TabSelection = .home
    @Published var selectedTool: ToolIdentifier? = nil
    
    let toolManager: ToolManager = .shared
    
    @Published var favoriteToolIds: Set<ToolIdentifier> = []
    
    /// Reads persisted favorite flags from `UserDefaults` and rebuilds the set.
    func loadFavoritesOnLaunch() {
        let allTools = toolManager.tools
        for tool in allTools {
            let key = "favorite_\(tool.id.rawValue)"
            if UserDefaults.standard.bool(forKey: key) == true {
                favoriteToolIds.insert(tool.id)
            }
        }
    }
    
    var recentToolIDs: [ToolIdentifier] = []
    
    var recentTools: [ToolItem] {
        recentToolIDs.compactMap { id in toolManager.tools.first(where: { $0.id == id }) }
    }
}

/// Tabs available in the main app container.
enum TabSelection: Hashable {
    case home
    case tools
    case settings
}
