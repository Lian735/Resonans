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
    let toolManager: ToolManager = .shared

    var favoriteToolIds: Set<ToolIdentifier> = []
    @Published var recentToolIDs: [ToolIdentifier] = []
    
    var recentTools: [ToolItem] {
        recentToolIDs.compactMap { id in toolManager.tools.first(where: { $0.id == id }) }
    }
}

enum TabSelection: Hashable {
    case home
    case tools
    case settings
}
