//
//  BgRemoverTool.swift
//  Resonans
//
//  Created by Kevin Dallian on 25/10/25.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import SwiftUI
import Vision

final class BgRemoverTool {
    func removeBackground(from image: UIImage) async throws -> UIImage {
        guard let inputImage = CIImage(image: image) else {
            throw BgRemoverError.convertError
        }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        let maskImage = try createMask(from: inputImage, orientation: orientation)
        let outputImage = applyMask(mask: maskImage, to: inputImage)
        return try convertToUIImage(ciImage: outputImage, originalImage: image)
    }

    private func createMask(from inputImage: CIImage, orientation: CGImagePropertyOrientation) throws -> CIImage {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(ciImage: inputImage, orientation: orientation)
        
        do {
            try handler.perform([request])
        } catch {
            throw BgRemoverError.createMaskError(error)
        }
        
        guard let result = request.results?.first else {
            throw BgRemoverError.emptyData
        }

        guard let maskBuffer = try? result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler) else {
            throw BgRemoverError.createMaskError(BgRemoverError.emptyData)
        }
        
        return CIImage(cvPixelBuffer: maskBuffer)
    }
    
    private func applyMask(mask: CIImage, to image: CIImage) -> CIImage {
        let filter = CIFilter.blendWithMask()

        filter.inputImage = image
        filter.maskImage = mask
        filter.backgroundImage = CIImage.empty()

        return (filter.outputImage ?? image).cropped(to: image.extent)
    }

    private func convertToUIImage(ciImage: CIImage, originalImage: UIImage) throws -> UIImage {
        guard let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent) else {
            throw BgRemoverError.convertError
        }

        return UIImage(cgImage: cgImage, scale: originalImage.scale, orientation: originalImage.imageOrientation)
    }
}

extension BgRemoverTool {
    enum BgRemoverError: Error, LocalizedError {
        case emptyData
        case createMaskError(Error)
        case convertError
        case unknownError
        
        var errorDescription: String? {
            switch self {
            case .emptyData:
                return "No mask or image data was produced."
            case .createMaskError(let error):
                return "Failed to create a segmentation mask: \(error.localizedDescription)"
            case .convertError:
                return "Failed to convert CIImage to UIImage."
            case .unknownError:
                return "An unknown error occurred."
            }
        }
    }
}
