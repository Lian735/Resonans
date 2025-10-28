//
//  BgRemoverViewModel.swift
//  Resonans
//
//  Created by Kevin Dallian on 25/10/25.
//

import Combine
import Foundation
import SwiftUI
import UIKit

final class BgRemoverViewModel: ObservableObject {
    @Published var recents: [RecentItem] = []
    @Published var useFullScreenSheet: Bool = false
    @Published var activeSheet: ActiveSheet?
    
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
}

extension BgRemoverViewModel {
    enum ActiveSheet: Identifiable {
        case photoLibrary, recents(URL), tool(image: UIImage), cameraNotAuthorized(status: AuthorizationStatus)
        var id: String { String(describing: self) }
    }
    
    @MainActor
    func showPhotoLibrary() {
        activeSheet = .photoLibrary
    }
}
