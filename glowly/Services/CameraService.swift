//
//  CameraService.swift
//  Glowly
//
//  Service for handling camera capture with AVFoundation
//

import Foundation
import SwiftUI
import AVFoundation
import Photos
import CoreImage
import Vision

/// Protocol for camera service operations
protocol CameraServiceProtocol: AnyObject {
    func setupCamera() async throws
    func startSession()
    func stopSession()
    func switchCamera()
    func capturePhoto() async throws -> UIImage
    func setFlashMode(_ mode: AVCaptureDevice.FlashMode)
    func setTorchMode(_ mode: AVCaptureDevice.TorchMode)
    func focus(at point: CGPoint)
    func setExposure(at point: CGPoint)
    func setZoom(_ factor: CGFloat)
}

/// Camera service implementation using AVFoundation
@MainActor
final class CameraService: NSObject, CameraServiceProtocol, ObservableObject {
    
    // MARK: - Properties
    
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    @Published var currentCameraPosition: AVCaptureDevice.Position = .front
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    @Published var torchMode: AVCaptureDevice.TorchMode = .off
    @Published var isSessionRunning = false
    @Published var zoomFactor: CGFloat = 1.0
    @Published var hasPortraitEffect = false
    @Published var isCapturing = false
    @Published var lastCapturedImage: UIImage?
    @Published var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    
    // AVFoundation components
    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let sessionQueue = DispatchQueue(label: "com.glowly.camera.session")
    private var photoCaptureCompletionHandler: ((Result<UIImage, Error>) -> Void)?
    
    // Camera device discovery
    private let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInDualCamera, .builtInWideAngleCamera, .builtInTrueDepthCamera],
        mediaType: .video,
        position: .unspecified
    )
    
    // Face detection
    private let faceDetectionRequest = VNDetectFaceRectanglesRequest()
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        checkCameraPermission()
    }
    
    // MARK: - Permission Handling
    
    private func checkCameraPermission() {
        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    func requestCameraPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                Task { @MainActor in
                    self.cameraPermissionStatus = granted ? .authorized : .denied
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    // MARK: - Camera Setup
    
    func setupCamera() async throws {
        guard cameraPermissionStatus == .authorized else {
            let granted = await requestCameraPermission()
            if !granted {
                throw CameraError.permissionDenied
            }
        }
        
        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }
    
    private func configureSession() {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        
        // Set session preset for high quality photos
        if captureSession.canSetSessionPreset(.photo) {
            captureSession.sessionPreset = .photo
        }
        
        // Add video input
        do {
            guard let videoDevice = getCamera(for: currentCameraPosition) else {
                throw CameraError.cameraUnavailable
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if captureSession.canAddInput(videoDeviceInput) {
                captureSession.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            } else {
                throw CameraError.inputError
            }
        } catch {
            print("Error setting up camera input: \(error)")
        }
        
        // Add photo output
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            
            // Configure photo output
            photoOutput.isHighResolutionCaptureEnabled = true
            
            // Enable portrait mode if available
            if photoOutput.isPortraitEffectsMatteDeliverySupported {
                photoOutput.isPortraitEffectsMatteDeliveryEnabled = true
                Task { @MainActor in
                    self.hasPortraitEffect = true
                }
            }
            
            // Enable depth data if available
            if photoOutput.isDepthDataDeliverySupported {
                photoOutput.isDepthDataDeliveryEnabled = true
            }
        }
        
        // Create preview layer
        Task { @MainActor in
            let preview = AVCaptureVideoPreviewLayer(session: captureSession)
            preview.videoGravity = .resizeAspectFill
            self.previewLayer = preview
        }
    }
    
    // MARK: - Camera Controls
    
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                Task { @MainActor in
                    self.isSessionRunning = true
                }
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                Task { @MainActor in
                    self.isSessionRunning = false
                }
            }
        }
    }
    
    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.captureSession.beginConfiguration()
            defer { self.captureSession.commitConfiguration() }
            
            // Remove current input
            if let currentInput = self.videoDeviceInput {
                self.captureSession.removeInput(currentInput)
            }
            
            // Toggle camera position
            let newPosition: AVCaptureDevice.Position = self.currentCameraPosition == .front ? .back : .front
            
            // Add new input
            do {
                guard let newCamera = self.getCamera(for: newPosition) else {
                    throw CameraError.cameraUnavailable
                }
                
                let newInput = try AVCaptureDeviceInput(device: newCamera)
                
                if self.captureSession.canAddInput(newInput) {
                    self.captureSession.addInput(newInput)
                    self.videoDeviceInput = newInput
                    
                    Task { @MainActor in
                        self.currentCameraPosition = newPosition
                    }
                }
            } catch {
                print("Error switching camera: \(error)")
            }
        }
    }
    
    // MARK: - Photo Capture
    
    func capturePhoto() async throws -> UIImage {
        guard !isCapturing else {
            throw CameraError.alreadyCapturing
        }
        
        await MainActor.run {
            isCapturing = true
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            self.photoCaptureCompletionHandler = { result in
                Task { @MainActor in
                    self.isCapturing = false
                }
                continuation.resume(with: result)
            }
            
            sessionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: CameraError.captureError)
                    return
                }
                
                let photoSettings = self.createPhotoSettings()
                self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
            }
        }
    }
    
    private func createPhotoSettings() -> AVCapturePhotoSettings {
        let settings: AVCapturePhotoSettings
        
        if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        } else {
            settings = AVCapturePhotoSettings()
        }
        
        // Configure flash
        if videoDeviceInput?.device.hasFlash ?? false {
            settings.flashMode = flashMode
        }
        
        // Enable high resolution
        settings.isHighResolutionPhotoEnabled = true
        
        // Enable portrait mode if available
        if hasPortraitEffect && photoOutput.isPortraitEffectsMatteDeliveryEnabled {
            settings.isPortraitEffectsMatteDeliveryEnabled = true
        }
        
        // Enable depth data if available
        if photoOutput.isDepthDataDeliveryEnabled {
            settings.isDepthDataDeliveryEnabled = true
        }
        
        return settings
    }
    
    // MARK: - Camera Settings
    
    func setFlashMode(_ mode: AVCaptureDevice.FlashMode) {
        flashMode = mode
    }
    
    func setTorchMode(_ mode: AVCaptureDevice.TorchMode) {
        guard let device = videoDeviceInput?.device,
              device.hasTorch else { return }
        
        sessionQueue.async {
            do {
                try device.lockForConfiguration()
                device.torchMode = mode
                device.unlockForConfiguration()
                
                Task { @MainActor in
                    self.torchMode = mode
                }
            } catch {
                print("Error setting torch mode: \(error)")
            }
        }
    }
    
    func focus(at point: CGPoint) {
        guard let device = videoDeviceInput?.device,
              device.isFocusPointOfInterestSupported else { return }
        
        sessionQueue.async {
            do {
                try device.lockForConfiguration()
                device.focusPointOfInterest = point
                device.focusMode = .autoFocus
                device.unlockForConfiguration()
            } catch {
                print("Error setting focus: \(error)")
            }
        }
    }
    
    func setExposure(at point: CGPoint) {
        guard let device = videoDeviceInput?.device,
              device.isExposurePointOfInterestSupported else { return }
        
        sessionQueue.async {
            do {
                try device.lockForConfiguration()
                device.exposurePointOfInterest = point
                device.exposureMode = .autoExpose
                device.unlockForConfiguration()
            } catch {
                print("Error setting exposure: \(error)")
            }
        }
    }
    
    func setZoom(_ factor: CGFloat) {
        guard let device = videoDeviceInput?.device else { return }
        
        sessionQueue.async {
            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = max(1.0, min(factor, device.activeFormat.videoMaxZoomFactor))
                device.unlockForConfiguration()
                
                Task { @MainActor in
                    self.zoomFactor = factor
                }
            } catch {
                print("Error setting zoom: \(error)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getCamera(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let devices = deviceDiscoverySession.devices
        
        // Try to find the best camera for the position
        if position == .front {
            // Prefer TrueDepth camera for selfies
            if let trueDepthCamera = devices.first(where: { $0.position == position && $0.deviceType == .builtInTrueDepthCamera }) {
                return trueDepthCamera
            }
        } else {
            // Prefer dual camera for rear
            if let dualCamera = devices.first(where: { $0.position == position && $0.deviceType == .builtInDualCamera }) {
                return dualCamera
            }
        }
        
        // Fallback to wide angle camera
        return devices.first { $0.position == position }
    }
    
    func detectFaces(in image: UIImage) async -> [FaceDetectionResult] {
        guard let cgImage = image.cgImage else { return [] }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([faceDetectionRequest])
            
            guard let observations = faceDetectionRequest.results else { return [] }
            
            return observations.map { observation in
                FaceDetectionResult(
                    boundingBox: observation.boundingBox,
                    confidence: observation.confidence,
                    faceQuality: evaluateFaceQuality(for: observation)
                )
            }
        } catch {
            print("Face detection error: \(error)")
            return []
        }
    }
    
    private func evaluateFaceQuality(for observation: VNFaceObservation) -> FaceQuality {
        // Simple quality assessment based on face size and confidence
        let faceArea = observation.boundingBox.width * observation.boundingBox.height
        let sizeScore = min(faceArea * 4, 1.0) // Larger faces score higher
        let confidenceScore = observation.confidence
        
        let overallScore = (sizeScore + confidenceScore) / 2
        
        return FaceQuality(
            overallScore: overallScore,
            lighting: 0.8, // Would need additional processing for real lighting assessment
            sharpness: 0.8, // Would need additional processing for real sharpness assessment
            pose: 0.8, // Would need additional processing for real pose assessment
            expression: 0.8 // Would need additional processing for real expression assessment
        )
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            photoCaptureCompletionHandler?(.failure(error))
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            photoCaptureCompletionHandler?(.failure(CameraError.captureError))
            return
        }
        
        // Apply orientation correction
        let correctedImage = correctImageOrientation(image)
        
        Task { @MainActor in
            self.lastCapturedImage = correctedImage
        }
        
        photoCaptureCompletionHandler?(.success(correctedImage))
    }
    
    private func correctImageOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: image.size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
}

// MARK: - Camera Errors

enum CameraError: LocalizedError {
    case permissionDenied
    case cameraUnavailable
    case inputError
    case captureError
    case alreadyCapturing
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Camera permission was denied. Please enable camera access in Settings."
        case .cameraUnavailable:
            return "Camera is not available on this device."
        case .inputError:
            return "Failed to configure camera input."
        case .captureError:
            return "Failed to capture photo."
        case .alreadyCapturing:
            return "A photo capture is already in progress."
        }
    }
}