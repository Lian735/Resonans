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
    func removeBackground(from image: UIImage) async throws -> UIImage? {
        guard let inputImage = CIImage(image: image) else {
            throw BgRemoverError.convertError
        }
        let maskImage = try createMask(from: inputImage)
        let outputImage = applyMask(mask: maskImage, to: inputImage)
        return try convertToUIImage(ciImage: outputImage)
    }
    
    private func createMask(from inputImage: CIImage) throws -> CIImage {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(ciImage: inputImage)
        
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
        
        return filter.outputImage ?? image
    }
    
    private func convertToUIImage(ciImage: CIImage) throws -> UIImage {
        guard let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent) else {
            throw BgRemoverError.convertError
        }
        
        return UIImage(cgImage: cgImage)
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
