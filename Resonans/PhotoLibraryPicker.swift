import SwiftUI
import PhotosUI
import Photos
import UniformTypeIdentifiers

/// A SwiftUI wrapper for `PHPickerViewController` to select media from the photo library.
///
/// `PhotoLibraryPicker` presents the system photo picker configured with custom settings.
/// It supports selecting videos, images, and live photos with automatic conversion to temporary file URLs.
///
/// Example usage:
/// ```swift
/// .sheet(isPresented: $showPhotoPicker) {
///     PhotoLibraryPicker(
///         config: .init(filter: .videos) { urls in
///             print("Selected \(urls.count) videos")
///             // Process the video URLs
///         }
///     )
/// }
/// ```
///
/// - Note: All selected media is copied to the app's temporary directory.
/// - Important: The picker automatically handles different media types (videos, images, live photos).
struct PhotoLibraryPicker: UIViewControllerRepresentable {
    let config: Config
    func makeCoordinator() -> Coordinator {
        Coordinator(config: config)
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var phPickerConfig = PHPickerConfiguration()
        phPickerConfig.filter = config.filter
        phPickerConfig.selectionLimit = config.selectionLimit
        let picker = PHPickerViewController(configuration: phPickerConfig)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
}

// MARK: - Coordinator
extension PhotoLibraryPicker {
    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let config: Config
        
        init(config: Config) {
            self.config = config
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard !results.isEmpty else { return }
            
            var collectedURLs: [URL] = []
            let group = DispatchGroup()
            
            for result in results {
                let provider = result.itemProvider
                
                // 🎥 Handle Videos
                if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    group.enter()
                    provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, _ in
                        if let url {
                            if let tempURL = self.copyToTemporary(url: url) {
                                collectedURLs.append(tempURL)
                            }
                        }
                        group.leave()
                    }
                }
                
                // 🖼️ Handle Images
                else if provider.canLoadObject(ofClass: UIImage.self) {
                    group.enter()
                    provider.loadObject(ofClass: UIImage.self) { object, _ in
                        if let image = object as? UIImage,
                           let tempURL = self.saveImageToTemporaryFile(image) {
                            collectedURLs.append(tempURL)
                        }
                        group.leave()
                    }
                }
                
                // 🎞️ Handle Live Photos (optional)
                else if provider.hasItemConformingToTypeIdentifier(UTType.livePhoto.identifier) {
                    group.enter()
                    provider.loadFileRepresentation(forTypeIdentifier: UTType.livePhoto.identifier) { url, _ in
                        if let url,
                           let tempURL = self.copyToTemporary(url: url) {
                            collectedURLs.append(tempURL)
                        }
                        group.leave()
                    }
                }
            }
            
            // ✅ Call completion after all items are processed
            group.notify(queue: .main) {
                self.config.onComplete(collectedURLs)
            }
        }
        
        // MARK: - Helpers
        private func copyToTemporary(url: URL) -> URL? {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
            try? FileManager.default.removeItem(at: tempURL)
            do {
                try FileManager.default.copyItem(at: url, to: tempURL)
                return tempURL
            } catch {
                print("❌ Failed to copy file:", error)
                return nil
            }
        }
        
        private func saveImageToTemporaryFile(_ image: UIImage) -> URL? {
            guard let data = image.pngData() else { return nil }
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".png")
            do {
                try data.write(to: tempURL)
                return tempURL
            } catch {
                print("❌ Failed to save image:", error)
                return nil
            }
        }
    }
}

// MARK: - Config
extension PhotoLibraryPicker {
    /// Configuration for ``PhotoLibraryPicker`` including selection limits, filters, and completion handler.
    ///
    /// Example:
    /// ```swift
    /// let config = PhotoLibraryPicker.Config(
    ///     selectionLimit: 5,
    ///     filter: .any(of: [.images, .videos])
    /// ) { urls in
    ///     print("Selected \(urls.count) items")
    /// }
    /// ```
    struct Config {
        let selectionLimit: Int
        let filter: PHPickerFilter?
        let onComplete: ([URL]) -> Void
        
        init(
            selectionLimit: Int = 0,
            filter: PHPickerFilter?,
            onComplete: @escaping ([URL]) -> Void
        ) {
            self.selectionLimit = selectionLimit
            self.filter = filter
            self.onComplete = onComplete
        }
    }
}
