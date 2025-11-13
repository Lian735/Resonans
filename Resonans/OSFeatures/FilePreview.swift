//
//  FilePreview.swift
//  Resonans
//
//  Created by Kevin Dallian on 11/11/25.
//

import SwiftUI
import UIKit

struct FilePreviewView: UIViewControllerRepresentable {
    let fileURL: URL
    
    func makeUIViewController(context: Context) -> UIViewController {
        // Create a host UIViewController for presentation
        let viewController = UIViewController()
        viewController.view.backgroundColor = .clear
        
        // Present the preview after the view appears
        DispatchQueue.main.async {
            let documentController = UIDocumentInteractionController(url: fileURL)
            documentController.delegate = context.coordinator
            context.coordinator.controller = documentController
            documentController.presentPreview(animated: true)
        }
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    final class Coordinator: NSObject, UIDocumentInteractionControllerDelegate {
        var controller: UIDocumentInteractionController?
        
        func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
            return UIApplication.shared.connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
                .first ?? UIViewController()
        }
    }
}
