//
//  AudioExtractorViewModel.swift
//  Resonans
//
//  Created by Kevin Dallian on 14/10/25.
//

import Combine
import Foundation
import SwiftData
import SwiftUI

final class AudioExtractorViewModel: ObservableObject {
    @Published var histories: [AudioHistory] = []
    var modelContext: ModelContext?
    
    func getAudioHistories() {
        guard let modelContext = modelContext else {
            print("No ModelContext available")
            return
        }
        do {
            let descriptor = History.allToolHistoriesDescriptor(ToolIdentifier.audioExtractor)
            let fetchedHistories = try modelContext.fetch(descriptor)
            let histories = fetchedHistories.compactMap { history in
                var duration: Double?
                if let data = history.metadata {
                    let metadata = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                    duration = metadata?["duration"] as? Double
                }
                return AudioHistory(
                    id: history.id,
                    title: history.title,
                    createdAt: history.createdAt,
                    fileUrl: history.fileUrl,
                    duration: duration ?? 0
                )
            }
            self.histories = histories
        } catch let error {
            print("Error getting audio histories : \(error)")
            self.histories = []
        }
    }
    
    func deleteHistory(id: UUID) {
        guard let modelContext = modelContext else { return }
        guard let index = histories.firstIndex(where: { $0.id == id }) else { return }
        let historyToBeDeleted = histories[index]
        histories.remove(at: index)
        do {
            try modelContext.delete(model: History.self, where: #Predicate { $0.id == id })
            try? FileStorage.shared.deleteFile(on: .documents, fileName: historyToBeDeleted.fileUrl?.absoluteString ?? "")
        } catch {
            print("Error deleting History with id \(id) : \(error)")
        }
    }
}
