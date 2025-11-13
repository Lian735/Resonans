//
//  AudioExtractorViewModel.swift
//  Resonans
//
//  Created by Kevin Dallian on 14/10/25.
//

import Combine
import Foundation
import SwiftData

final class AudioExtractorViewModel: ObservableObject {
    @Published var recents: [RecentItem] = []
    @Published var histories: [History] = []
    let cacheManager: CacheManager
    
    init(cacheManager: CacheManager) {
        self.cacheManager = cacheManager
    }
    
    func reloadRecents() {
        self.recents = cacheManager.loadRecentConversions()
    }
    
    func getAudioHistories(modelContext: ModelContext) {
        let toolRaw = ToolIdentifier.audioExtractor.rawValue
        let descriptor = FetchDescriptor<History>(
            predicate: #Predicate { history in
                history.tool == toolRaw
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            let histories = try modelContext.fetch(descriptor)
            self.histories = histories
        } catch let error {
            print("Error getting audio histories : \(error)")
        }
    }
}
