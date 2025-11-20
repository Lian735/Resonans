//
//  RemoveBackgroundViewModel.swift
//  Resonans
//
//  Created by Kevin Dallian on 25/10/25.
//

import Combine
import UIKit
import SwiftData

final class RemoveBackgroundViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var outputImage: UIImage?
    @Published var isLoading: Bool = false
    @Published var fileUrl: URL?
    let image: UIImage
    let tool: BgRemoverTool
    let modelContext: ModelContext
    
    init(image: UIImage, modelContext: ModelContext) {
        self.image = image
        self.tool = BgRemoverTool()
        self.modelContext = modelContext
    }
    
    func removeBackground() {
        isLoading = true
        Task {
            do {
                let finalImage = try await tool.removeBackground(from: image)
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.isLoading = false
                    if let image = finalImage {
                        self.fileUrl = saveImageToLocal(image: image)
                        self.outputImage = image
                    }
                }
            } catch let error {
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func saveImageToLocal(image: UIImage) -> URL? {
        guard let data = image.pngData() else { return nil }
        let fileName = UUID().uuidString + ".png"
        do {
            let savedUrl = try FileStorage.shared.saveFile(on: .documents, fileName: fileName, fileData: data)
            let history = History(
                title: fileName,
                tool: ToolIdentifier.bgRemover.rawValue,
                fileUrl: savedUrl
            )
            modelContext.insert(history)
            try modelContext.save()
            return savedUrl
        } catch let error {
            print("Error saving image to local: \(error.localizedDescription)")
            return nil
        }
    }
}
