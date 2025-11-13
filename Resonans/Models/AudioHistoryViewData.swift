//
//  AudioHistoryViewData.swift
//  Resonans
//
//  Created by Kevin Dallian on 13/11/25.
//

import Foundation

struct AudioHistoryViewData: Codable, Equatable {
    let id: UUID
    let title: String
    let createdAt: Date
    let fileUrl: URL?
    let duration: Double
}
