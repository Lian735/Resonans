//
//  RemoveBackgroundViewModel.swift
//  Resonans
//
//  Created by Kevin Dallian on 25/10/25.
//

import Combine
import UIKit

final class RemoveBackgroundViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var outputImage: UIImage?
    @Published var isLoading: Bool = false
    let image: UIImage
    let tool: BgRemoverTool
    
    init(image: UIImage) {
        self.image = image
        self.tool = BgRemoverTool()
    }
    
    func removeBackground() {
        isLoading = true
        Task {
            do {
                let finalImage = try await tool.removeBackground(from: image)
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.isLoading = false
                    self.outputImage = finalImage
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
}
