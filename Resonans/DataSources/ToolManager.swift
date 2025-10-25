//
//  ToolManager.swift
//  Resonans
//
//  Created by Kevin Dallian on 25/10/25.
//

import Combine
import Foundation

final class ToolManager: ObservableObject {
    static var shared = ToolManager()
    
    @Published var tools: [ToolItem] = []
    
    private init() {
        loadTools()
    }
    
    private let localToolIdentifiers: [ToolIdentifier] = [.audioExtractor, .dummy]
    
    private func loadTools() {
        let localTools = localToolIdentifiers.map { $0.tool }
        self.tools = localTools
    }
}
