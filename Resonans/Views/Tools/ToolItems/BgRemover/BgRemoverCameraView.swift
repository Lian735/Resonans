//
//  BgRemoverCameraView.swift
//  Resonans
//
//  Created by Kevin Dallian on 28/10/25.
//

import SwiftUI
import AVFoundation

struct BgRemoverCameraView: View {
    @Environment(\.dismiss) private var dismiss
    var cameraManager: Camera
    var onPhotoCaptured: ((UIImage) -> Void)?
    var onClose: (() -> Void)?
    
    init(cameraManager: Camera, onPhotoCaptured: ((UIImage) -> Void)? = nil, onClose: (() -> Void)? = nil) {
        self.cameraManager = cameraManager
        self.onPhotoCaptured = onPhotoCaptured
        self.onClose = onClose
    }
    
    var body: some View {
        ZStack {
            cameraPreview
            cameraTools
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .task {
            do {
                try await cameraManager.configureSession()
                try await cameraManager.startSession()
            } catch let error {
                print("Error starting session : \(error.localizedDescription)")
            }
        }
    }
    
    var cameraPreview: some View {
        #if targetEnvironment(simulator)
        ZStack {
            Color.black
                .ignoresSafeArea()
            Text("This is a Camera Preview")
        }
        
        #else
        CameraPreview(session: cameraManager.session)
            .ignoresSafeArea()
        #endif
    }
    
    var cameraTools: some View {
        VStack {
            HStack {
                Button {
                    onClose?()
                } label: {
                    Image(systemName: "xmark")
                        .typography(.custom(size: 28, weight: .bold), color: .white)
                        .padding(.top, 14)
                }
                Spacer()
            }
            Spacer()
            Button {
                handlePhotoCapture()
            } label: {
                Circle()
                    .fill(.white)
                    .stroke(.black, lineWidth: 12)
                    .stroke(.white, lineWidth: 6)
                    .frame(width: 54, height: 54)
            }
        }
        .padding(.horizontal, 24)
    }
    
    private func handlePhotoCapture() {
        Task {
            do {
                #if targetEnvironment(simulator)
                print("Capture image")
                #else
                let image = try await cameraManager.capturePhoto()
                onPhotoCaptured?(image)
                #endif
            } catch let error {
                print("Error Capture Photo : \(error)")
            }
        }
    }
}

#Preview {
    class MockCamera: Camera {
        var session: AVCaptureSession = AVCaptureSession()
        func configureSession() async throws {}
        func startSession() async throws {}
        func stopSession() {}
        func capturePhoto() async throws -> UIImage { UIImage() }
        func checkAuthorization() -> AuthorizationStatus { return .authorized }
        func requestCameraAccess() async -> Bool { return true }
    }

    return ZStack {
        Color.black
        BgRemoverCameraView(
            cameraManager: MockCamera(),
            onPhotoCaptured: { image in
                print("onPhotoCapture")
            },
            onClose: {
                print("onClose")
            }
        )
    }
}
