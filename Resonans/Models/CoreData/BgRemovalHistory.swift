//
//  BgRemovalHistory.swift
//  Resonans
//
//  Created by Kevin Dallian on 19/11/25.
//

import Foundation

struct BgRemovalHistory: Codable {
    let id: UUID
    let title: String
    let createdAt: Date
    let fileUrl: URL?
}
