//
//  History.swift
//  Resonans
//
//  Created by Kevin Dallian on 10/11/25.
//

import Foundation
import SwiftData

@Model
class History {
    var id: UUID
    var title: String
    var tool: String
    var createdAt: Date
    
    var fileUrl: URL?
    var metadata: Data?
    
    init(id: UUID = UUID(), title: String, tool: String, createdAt: Date = Date(), fileUrl: URL?, metadata: Data? = nil) {
        self.id = id
        self.title = title
        self.tool = tool
        self.fileUrl = fileUrl
        self.createdAt = createdAt
        self.metadata = metadata
    }
}
