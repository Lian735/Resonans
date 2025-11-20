//
//  BgRemoverViewModel.swift
//  Resonans
//
//  Created by Kevin Dallian on 25/10/25.
//

import Combine
import Foundation
import SwiftData
import SwiftUI
import UIKit

final class BgRemoverViewModel: ObservableObject {
    @Published var recents: [RecentItem] = []
    @Published var useFullScreenSheet: Bool = false
    @Published var activeSheet: ActiveSheet?
    @Published var histories: [BgRemovalHistory] = []
    
    var modelContext: ModelContext?
    
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
    
    func handleImageFromPhotoPicker(url: URL) {
        if let image = getImageFromUrl(url) {
            handleOpenTool(with: image)
        }
    }
    
    func handleImageFromPhotoLibrary(_ image: UIImage) {
        handleOpenTool(with: image)
    }
    
    func handleOpenCamera() {
        let status = getCameraAuthorization()
        if status == .authorized {
            withAnimation(.spring) {
                self.useFullScreenSheet = true
            }
            
        } else {
            activeSheet = .cameraNotAuthorized(status: status)
        }
    }
    
    private func handleOpenTool(with image: UIImage) {
        if activeSheet != nil {
            self.activeSheet = nil
        }
        self.activeSheet = .tool(image: image)
    }
    
    private func getCameraAuthorization() -> AuthorizationStatus {
        let cameraManager = CameraManager.shared
        return cameraManager.checkAuthorization()
    }
    
    func handleRecentExport(_ item: RecentItem) {
        let url = item.fileURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            reloadRecents()
            return
        }
        activeSheet = .recents(url)
    }
    
    func fetchHistories() {
        guard let modelContext else { return }
        do {
            let descriptor = History.allToolHistoriesDescriptor(ToolIdentifier.bgRemover)
            let fetchedHistories = try modelContext.fetch(descriptor)
            let histories = fetchedHistories.compactMap {
                BgRemovalHistory(id: $0.id, title: $0.title, createdAt: $0.createdAt, fileUrl: $0.fileUrl)
            }
            self.histories = histories
        } catch {
            print("Error getting bgRemoval histories : \(error)")
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

extension BgRemoverViewModel {
    enum ActiveSheet: Identifiable {
        case photoLibrary, recents(URL), tool(image: UIImage), cameraNotAuthorized(status: AuthorizationStatus), filePreview(URL)
        var id: String { String(describing: self) }
    }
    
    @MainActor
    func showPhotoLibrary() {
        activeSheet = .photoLibrary
    }
}
