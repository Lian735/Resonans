//
//  Project.swift
//  Resonans
//
//  Created by Comic-Star_55 on 24.11.25.
//
import SwiftData
import Foundation

@Model
class VideoProject: Identifiable {
    var id: UUID
    
    var title: String
    
    var assets: [Asset]
    
    var timelines: [Timeline]
    
    struct Asset: Identifiable, Codable {
        var id: UUID = UUID()
        var name: String
        
        var url: URL
    }
    
    struct Timeline: Identifiable, Codable {
        var id: UUID = UUID()
        
        var assets: [ReferedAsset]
        
        struct ReferedAsset: Identifiable, Codable {
            var id: UUID = UUID()
            var asset: Asset
            
            var start: TimeInterval
            var usedInterval: ClosedRange<TimeInterval>
        }
    }
    
    
    init(id: UUID, title: String, assets: [Asset], timelines: [Timeline]) {
        self.id = id
        
        self.assets = assets
        self.timelines = timelines
        self.title = title
    }
    
    
    ///Create a new, empty project
    convenience init(title: String = "Untitles Project") {
        self.init(id: UUID(), title: title, assets: [], timelines: [])
    }
}
