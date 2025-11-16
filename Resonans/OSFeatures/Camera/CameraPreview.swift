//
//  CameraPreview.swift
//  Resonans
//
//  Created by Kevin Dallian on 28/10/25.
//

import AVFoundation
import SwiftUI

/// Wraps an `AVCaptureSession` for display inside SwiftUI views.
public struct CameraPreview: UIViewRepresentable {
    /// Capture session providing the video feed.
    let session: AVCaptureSession
    /// Controls how the video is scaled within the preview layer.
    let videoGravity: AVLayerVideoGravity
    
    public init(
        session: AVCaptureSession,
        videoGravity: AVLayerVideoGravity = .resizeAspect
    ) {
        self.session = session
        self.videoGravity = videoGravity
    }
    
    public func makeUIView(context: Context) -> UIView {
        let previewView = CameraContainer()
        previewView.videoPreviewLayer?.videoGravity = videoGravity
        previewView.videoPreviewLayer?.session = session
        return previewView
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) { }
}

/// UIView subclass that exposes its backing `AVCaptureVideoPreviewLayer`.
private class CameraContainer: UIView {
    public override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    public var videoPreviewLayer: AVCaptureVideoPreviewLayer? {
        layer as? AVCaptureVideoPreviewLayer
    }
}
