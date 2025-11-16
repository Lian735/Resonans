//
//  CameraManager.swift
//  Resonans
//
//  Created by Kevin Dallian on 28/10/25.
//

import AVFoundation
import Combine
import Foundation
import UIKit

/// Manages camera capture configuration, authorization, and photo capture.
final class CameraManager: NSObject, ObservableObject {
    /// Shared singleton used by the background remover and other features.
    static let shared: CameraManager = .init()
    
    private override init() { }
    
    // MARK: - Private Session Components
    var session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "CameraManager.SessionQueue")
    private var photoOutput = AVCapturePhotoOutput()
    private var videoOutput = AVCaptureMovieFileOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var currentContinuation: CheckedContinuation<UIImage, Error>?
}

// MARK: - Camera
extension CameraManager: Camera {
    /// Configures the capture session with a back wide-angle camera and photo output.
    func configureSession() async throws {
        try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async {
                do {
                    self.session.beginConfiguration()
                    self.session.sessionPreset = .photo
                    
                    self.session.inputs.forEach { self.session.removeInput($0) }
                    self.session.outputs.forEach { self.session.removeOutput($0) }
                    
                    // MARK: - Video Input
                    guard let device = AVCaptureDevice.default(
                        .builtInWideAngleCamera,
                        for: .video,
                        position: .back
                    ) else {
                        throw CameraError.noDevice
                    }
                    
                    let videoInput = try AVCaptureDeviceInput(device: device)
                    guard self.session.canAddInput(videoInput) else {
                        throw CameraError.failedToAddInput
                    }
                    self.session.addInput(videoInput)
                    self.videoDeviceInput = videoInput
                    
                    // MARK: - Photo Output
                    guard self.session.canAddOutput(self.photoOutput) else {
                        throw CameraError.failedToAddOutput
                    }
                    self.session.addOutput(self.photoOutput)
                    
                    self.session.commitConfiguration()
                    continuation.resume()
                } catch let error {
                    print("Unable to configure Camera Session: \(error.localizedDescription)")
                    self.session.commitConfiguration()
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Starts the capture session after verifying authorization.
    func startSession() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async {
                do {
                    guard self.checkAuthorization() == .authorized else {
                        continuation.resume(throwing: CameraError.unauthorized)
                        return
                    }
                    
                    guard !self.session.isRunning else {
                        continuation.resume()
                        return
                    }
                    self.session.startRunning()

                    if !self.session.isRunning {
                        throw CameraError.configurationFailed("Failed to start capture session.")
                    }

                    continuation.resume()
                } catch {
                    continuation.resume(throwing: CameraError.configurationFailed(error.localizedDescription))
                }
            }
        }
    }
    
    /// Stops the capture session if running.
    func stopSession() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
    
    /// Captures a single still image from the active session.
    func capturePhoto() async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            let settings = AVCapturePhotoSettings()
            self.currentContinuation = continuation
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
}

// MARK: Photo Delegate
extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard let currentContinuation else { return }
        defer { self.currentContinuation = nil }
        if let error {
            currentContinuation.resume(throwing: error)
            return
        }
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            currentContinuation.resume(throwing: CameraError.convertFailed)
            return
        }
        currentContinuation.resume(returning: image)
    }
}

// MARK: Authorization
extension CameraManager {
    /// Reads the current camera authorization status.
    func checkAuthorization() -> AuthorizationStatus {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined: return .notDetermined
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        @unknown default: return .notDetermined
        }
    }
    
    @MainActor
    /// Prompts the user for camera access permission.
    func requestCameraAccess() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }
}

// MARK: - Error Types
extension CameraManager {
    /// Errors that can occur while configuring or capturing from the camera.
    enum CameraError: LocalizedError {
        case unauthorized
        case noDevice
        case failedToAddInput
        case failedToAddOutput
        case configurationFailed(String)
        case convertFailed

        var errorDescription: String? {
            switch self {
            case .unauthorized: return "Camera access not authorized."
            case .noDevice: return "No camera device found."
            case .failedToAddInput: return "Unable to add camera input."
            case .failedToAddOutput: return "Unable to add camera output."
            case .configurationFailed(let message): return "Camera configuration failed: \(message)"
            case .convertFailed: return "Convert Data Failed"
            }
        }
    }
}

/// Requirements for any camera manager implementation.
protocol Camera {
    var session: AVCaptureSession { get }
    func configureSession() async throws
    func startSession() async throws
    func stopSession()
    func capturePhoto() async throws -> UIImage
    
    func checkAuthorization() -> AuthorizationStatus
    func requestCameraAccess() async -> Bool
}
