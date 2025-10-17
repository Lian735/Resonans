//
//  AudioExtractorViewModel.swift
//  Resonans
//
//  Created by Kevin Dallian on 14/10/25.
//

import Combine
import Foundation

final class AudioExtractorViewModel: ObservableObject {
    @Published var recents: [RecentItem] = []
    let cacheManager: CacheManager
    
    init(cacheManager: CacheManager) {
        self.cacheManager = cacheManager
    }
    
    func reloadRecents() {
        self.recents = cacheManager.loadRecentConversions()
    }
}
