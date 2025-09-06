import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct VideoPicker: UIViewControllerRepresentable {
    var onComplete: (URL) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(onComplete: onComplete) }
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .videos
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var onComplete: (URL) -> Void
        init(onComplete: @escaping (URL) -> Void) { self.onComplete = onComplete }
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let item = results.first else { return }
            if item.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                item.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, _ in
                    if let url = url {
                        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                        try? FileManager.default.removeItem(at: tempURL)
                        try? FileManager.default.copyItem(at: url, to: tempURL)
                        DispatchQueue.main.async { self.onComplete(tempURL) }
                    }
                }
            }
        }
    }
}
