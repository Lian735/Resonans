//
//  BgRemoverViewModel.swift
//  Resonans
//
//  Created by Kevin Dallian on 25/10/25.
//

import Combine
import Foundation
import UIKit

final class BgRemoverViewModel: ObservableObject {
    @Published var recents: [RecentItem] = []
    let cacheManager: CacheManager
    
    init() {
        self.cacheManager = .shared
    }
    
    func reloadRecents() {
        self.recents = cacheManager.loadRecentConversions()
    }
    
    func getImageFromUrl(_ url: URL) -> UIImage? {
        do {
            let imageData = try Data(contentsOf: url)
            return UIImage(data: imageData)
        } catch {
            return nil
        }
    }
}
