//
//  PhotoService.swift
//  Glowly
//
//  Service for handling photo import/export and library operations
//

import Foundation
import SwiftUI
import Photos
import PhotosUI

/// Protocol for photo service operations
protocol PhotoServiceProtocol {
    func requestPhotoLibraryPermission() async -> Bool
    func requestCameraPermission() async -> Bool
    func importPhoto(from source: PhotoSource) async throws -> GlowlyPhoto
    func savePhoto(_ photo: GlowlyPhoto, toLibrary: Bool) async throws -> Bool
    func deletePhoto(_ photo: GlowlyPhoto) async throws
    func loadPhotos() async throws -> [GlowlyPhoto]
    func generateThumbnail(for image: UIImage, size: CGSize) async -> UIImage?
}

/// Implementation of photo service
@MainActor
final class PhotoService: PhotoServiceProtocol, ObservableObject {
    
    // MARK: - Properties
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    
    // MARK: - Initialization
    init() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    // MARK: - Permission Handling
    
    /// Request permission to access photo library
    func requestPhotoLibraryPermission() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        authorizationStatus = status
        return status == .authorized || status == .limited
    }
    
    /// Request permission to access camera
    func requestCameraPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    // MARK: - Photo Import
    
    /// Import a photo from specified source
    func importPhoto(from source: PhotoSource) async throws -> GlowlyPhoto {
        isLoading = true
        defer { isLoading = false }
        
        switch source {
        case .camera:
            return try await importFromCamera()
        case .photoLibrary:
            return try await importFromPhotoLibrary()
        case .imported:
            return try await importFromFiles()
        }
    }
    
    private func importFromCamera() async throws -> GlowlyPhoto {
        // Camera import will be handled by the camera view
        // This is a placeholder implementation
        throw PhotoServiceError.operationNotSupported
    }
    
    private func importFromPhotoLibrary() async throws -> GlowlyPhoto {
        guard authorizationStatus == .authorized || authorizationStatus == .limited else {
            throw PhotoServiceError.permissionDenied
        }
        
        // This will be implemented with PhotosPicker in SwiftUI
        throw PhotoServiceError.operationNotSupported
    }
    
    private func importFromFiles() async throws -> GlowlyPhoto {
        // File import will be handled by document picker
        throw PhotoServiceError.operationNotSupported
    }
    
    // MARK: - Photo Export
    
    /// Save photo to device or photo library
    func savePhoto(_ photo: GlowlyPhoto, toLibrary: Bool = true) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        guard let imageData = photo.enhancedImage ?? photo.originalImage else {
            throw PhotoServiceError.invalidImageData
        }
        
        guard let image = UIImage(data: imageData) else {
            throw PhotoServiceError.invalidImageData
        }
        
        if toLibrary {
            return try await saveToPhotoLibrary(image: image)
        } else {
            // Save to app documents directory
            return try await saveToDocuments(photo: photo)
        }
    }
    
    private func saveToPhotoLibrary(image: UIImage) async throws -> Bool {
        guard authorizationStatus == .authorized else {
            throw PhotoServiceError.permissionDenied
        }
        
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                PHAssetCreationRequest.creationRequestForAsset(from: image)
            }) { success, error in
                if let error = error {
                    print("Error saving to photo library: \(error)")
                    continuation.resume(returning: false)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }
    
    private func saveToDocuments(photo: GlowlyPhoto) async throws -> Bool {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "\(photo.id.uuidString).jpg"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        guard let imageData = photo.enhancedImage ?? photo.originalImage else {
            throw PhotoServiceError.invalidImageData
        }
        
        try imageData.write(to: fileURL)
        return true
    }
    
    // MARK: - Photo Management
    
    /// Delete a photo from the app
    func deletePhoto(_ photo: GlowlyPhoto) async throws {
        // Remove from local storage
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "\(photo.id.uuidString).jpg"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
    
    /// Load photos from local storage
    func loadPhotos() async throws -> [GlowlyPhoto] {
        isLoading = true
        defer { isLoading = false }
        
        // Load from local storage - this would be implemented with Core Data or similar
        // For now, return empty array
        return []
    }
    
    // MARK: - Utility Methods
    
    /// Generate thumbnail for an image
    func generateThumbnail(for image: UIImage, size: CGSize = CGSize(width: 150, height: 150)) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let thumbnailImage = image.preparingThumbnail(of: size)
                DispatchQueue.main.async {
                    continuation.resume(returning: thumbnailImage)
                }
            }
        }
    }
    
    /// Extract metadata from image
    func extractMetadata(from image: UIImage) -> PhotoMetadata {
        let imageSize = image.size
        let scale = image.scale
        let actualSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        
        // Estimate file size (this would be more accurate with actual image data)
        let estimatedFileSize = Int64(actualSize.width * actualSize.height * 4) // 4 bytes per pixel for RGBA
        
        return PhotoMetadata(
            width: Int(actualSize.width),
            height: Int(actualSize.height),
            fileSize: estimatedFileSize,
            format: "JPEG",
            colorSpace: "sRGB"
        )
    }
    
    /// Convert UIImage to Data
    func imageToData(_ image: UIImage, quality: Float = 0.8) -> Data? {
        return image.jpegData(compressionQuality: CGFloat(quality))
    }
    
    /// Convert Data to UIImage
    func dataToImage(_ data: Data) -> UIImage? {
        return UIImage(data: data)
    }
}

// MARK: - PhotoServiceError

enum PhotoServiceError: LocalizedError {
    case permissionDenied
    case invalidImageData
    case operationNotSupported
    case fileNotFound
    case saveFailed
    case loadFailed
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Permission to access photos was denied. Please enable photo access in Settings."
        case .invalidImageData:
            return "The image data is invalid or corrupted."
        case .operationNotSupported:
            return "This operation is not yet supported."
        case .fileNotFound:
            return "The requested file could not be found."
        case .saveFailed:
            return "Failed to save the photo."
        case .loadFailed:
            return "Failed to load the photo."
        }
    }
}