import SwiftUI
import UniformTypeIdentifiers

/// Wraps `UIDocumentPickerViewController` to select movie files.
struct FilePicker: UIViewControllerRepresentable {
    /// Completion handler returning the chosen file URL.
    var onComplete: (URL) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(onComplete: onComplete) }
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [.movie]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        var onComplete: (URL) -> Void
        init(onComplete: @escaping (URL) -> Void) { self.onComplete = onComplete }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onComplete(url)
        }
    }
}
