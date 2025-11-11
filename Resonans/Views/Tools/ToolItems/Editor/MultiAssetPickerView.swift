import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

public struct PickedAsset: Identifiable {
    public let id = UUID()
    public let image: UIImage?
    public let videoURL: URL?
    public let result: PHPickerResult
}

public struct MultiAssetPickerView: UIViewControllerRepresentable {
    public typealias UIViewControllerType = PHPickerViewController

    private let selectionLimit: Int
    private let onFinish: ([PickedAsset]) -> Void

    public init(selectionLimit: Int = 0, onFinish: @escaping ([PickedAsset]) -> Void) {
        self.selectionLimit = selectionLimit
        self.onFinish = onFinish
    }

    public func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = selectionLimit // 0 = unlimited
        config.filter = .any(of: [.images, .videos])

        let controller = PHPickerViewController(configuration: config)
        controller.delegate = context.coordinator
        return controller
    }

    public func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    public final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let onFinish: ([PickedAsset]) -> Void

        init(onFinish: @escaping ([PickedAsset]) -> Void) {
            self.onFinish = onFinish
        }

        public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard !results.isEmpty else {
                picker.dismiss(animated: true)
                onFinish([])
                return
            }

            let group = DispatchGroup()
            var picked: [PickedAsset] = []
            let lock = NSLock()

            for result in results {
                let provider = result.itemProvider

                if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    group.enter()
                    provider.loadObject(ofClass: UIImage.self) { object, error in
                        defer { group.leave() }
                        if let image = object as? UIImage {
                            lock.lock(); picked.append(PickedAsset(image: image, videoURL: nil, result: result)); lock.unlock()
                        }
                    }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    group.enter()
                    provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                        defer { group.leave() }
                        guard let url else { return }
                        // Copy to a temp location to persist beyond picker lifecycle
                        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString).appendingPathExtension(url.pathExtension)
                        do {
                            try FileManager.default.copyItem(at: url, to: tempURL)
                            lock.lock(); picked.append(PickedAsset(image: nil, videoURL: tempURL, result: result)); lock.unlock()
                        } catch {
                            // Ignore copy errors
                        }
                    }
                }
            }

            group.notify(queue: .main) {
                picker.dismiss(animated: true)
                self.onFinish(picked)
            }
        }
    }
}

public struct MultiAssetPickerSheet: View {
    @Binding var isPresented: Bool
    let selectionLimit: Int
    let onFinish: ([PickedAsset]) -> Void

    public init(isPresented: Binding<Bool>, selectionLimit: Int = 0, onFinish: @escaping ([PickedAsset]) -> Void) {
        self._isPresented = isPresented
        self.selectionLimit = selectionLimit
        self.onFinish = onFinish
    }

    public var body: some View {
        MultiAssetPickerView(selectionLimit: selectionLimit) { assets in
            isPresented = false
            onFinish(assets)
        }
    }
}
