//
//  ToolManager.swift
//  Resonans
//
//  Created by Kevin Dallian on 25/10/25.
//

import Combine
import Foundation

/// Loads and exposes the list of available tools for the app.
///
/// The manager currently builds tools from a static list of identifiers, but
/// the structure allows expanding to remote configuration later. It is shared
/// as a singleton to keep tool metadata consistent across tabs.
final class ToolManager: ObservableObject {
    /// Shared instance consumed by view models.
    static var shared = ToolManager()

    /// Published array of tools displayed throughout the UI.
    @Published var tools: [ToolItem] = []

    private init() {
        loadTools()
    }

    private let localToolIdentifiers: [ToolIdentifier] = [.audioExtractor, .bgRemover, .editor]

    /// Populates ``tools`` from the local identifier list.
    private func loadTools() {
        let localTools = localToolIdentifiers.map { $0.tool }
        self.tools = localTools
    }
}
