import SwiftUI
import UniformTypeIdentifiers

/// A SwiftUI wrapper for `UIDocumentPickerViewController` to select video files.
///
/// `FilePicker` presents the system document picker configured to select movie files.
/// When the user selects a file, it's automatically copied to a temporary location and the URL is provided via the completion handler.
///
/// Example usage:
/// ```swift
/// .sheet(isPresented: $showFilePicker) {
///     FilePicker { url in
///         print("Selected video: \(url)")
///         // Process the video file
///     }
/// }
/// ```
///
/// - Note: The picker is configured with `asCopy: true`, so files are copied rather than referenced.
/// - Important: Only movie files (``UTType.movie``) can be selected.
struct FilePicker: UIViewControllerRepresentable {
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
