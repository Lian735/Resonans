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
final class ContentViewModel: ObservableObject {
    @Published var showOnboarding: Bool = false
    
    @Published var selectedTab: TabSelection = .home
    @Published var selectedTool: ToolItem.Identifier? = nil
    
    var favoriteToolIds: Set<ToolItem.Identifier> = []
    var recentToolIDs: [ToolItem.Identifier] = []
    
    var recentTools: [ToolItem] {
        recentToolIDs.compactMap { id in ToolItem.all.first(where: { $0.id == id }) }
    }
}

enum TabSelection: Hashable {
    case home
    case tools
    case settings
}
