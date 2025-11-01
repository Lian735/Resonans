import UIKit

extension UIImage {
    /// Returns an image rendered in the `.up` orientation to avoid visual rotation issues
    /// after capturing from the camera or importing from external sources.
    func normalizedForDisplay() -> UIImage {
        guard imageOrientation != .up else { return self }

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
