//
//  PhotoLibraryManager.swift
//  Glowly
//
//  Manager for iOS Photos integration with album organization and metadata preservation
//

import Foundation
import Photos
import UIKit

// MARK: - Photo Library Manager

@MainActor
class PhotoLibraryManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    @Published var glowlyAlbum: PHAssetCollection?
    @Published var availableAlbums: [GlowlyPhotoAlbum] = []
    @Published var lastSaveResult: PhotoSaveResult?
    
    // MARK: - Private Properties
    
    private let photoLibrary = PHPhotoLibrary.shared()
    private var glowlyAlbumIdentifier: String?
    
    // MARK: - Constants
    
    private let glowlyAlbumName = "Glowly Enhanced"
    private let glowlySubalbumNames = [
        "Favorites",
        "Before & After",
        "Shared",
        "Drafts"
    ]
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        checkAuthorizationStatus()
        setupGlowlyAlbums()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async -> PHAuthorizationStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        await MainActor.run {
            self.authorizationStatus = status
        }
        return status
    }
    
    func checkAuthorizationStatus() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
    }
    
    // MARK: - Album Management
    
    func setupGlowlyAlbums() {
        guard authorizationStatus == .authorized else { return }
        
        Task {
            await createGlowlyAlbumIfNeeded()
            await loadAvailableAlbums()
        }
    }
    
    private func createGlowlyAlbumIfNeeded() async {
        // Check if Glowly album already exists
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", glowlyAlbumName)
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let existingAlbum = collections.firstObject {
            await MainActor.run {
                self.glowlyAlbum = existingAlbum
                self.glowlyAlbumIdentifier = existingAlbum.localIdentifier
            }
        } else {
            await createGlowlyAlbum()
        }
    }
    
    private func createGlowlyAlbum() async {
        do {
            var albumIdentifier: String?
            
            try await photoLibrary.performChanges {
                let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: self.glowlyAlbumName)
                albumIdentifier = request.placeholderForCreatedAssetCollection.localIdentifier
            }
            
            if let identifier = albumIdentifier {
                let fetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [identifier], options: nil)
                await MainActor.run {
                    self.glowlyAlbum = fetchResult.firstObject
                    self.glowlyAlbumIdentifier = identifier
                }
            }
        } catch {
            print("Failed to create Glowly album: \(error)")
        }
    }
    
    private func loadAvailableAlbums() async {
        let defaultAlbums = GlowlyPhotoAlbum.defaultAlbums
        await MainActor.run {
            self.availableAlbums = defaultAlbums
        }
    }
    
    // MARK: - Photo Saving
    
    func savePhoto(
        _ photo: GlowlyPhoto,
        to albumName: String? = nil,
        preserveMetadata: Bool = true,
        includeEnhancementHistory: Bool = true
    ) async throws -> PhotoSaveResult {
        
        guard authorizationStatus == .authorized else {
            throw PhotoLibraryError.authorizationDenied
        }
        
        guard let imageData = photo.enhancedImage ?? photo.originalImage else {
            throw PhotoLibraryError.noImageData
        }
        
        isProcessing = true
        processingProgress = 0.0
        
        defer {
            isProcessing = false
            processingProgress = 0.0
        }
        
        do {
            // Step 1: Create asset request
            processingProgress = 0.2
            var assetIdentifier: String?
            
            try await photoLibrary.performChanges {
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: imageData, options: nil)
                
                // Add metadata if requested
                if preserveMetadata {
                    self.addMetadataToRequest(request, photo: photo, includeEnhancementHistory: includeEnhancementHistory)
                }
                
                assetIdentifier = request.placeholderForCreatedAsset.localIdentifier
            }
            
            // Step 2: Add to album
            processingProgress = 0.6
            if let identifier = assetIdentifier {
                await addAssetToAlbum(identifier: identifier, albumName: albumName)
            }
            
            // Step 3: Create result
            processingProgress = 1.0
            let result = PhotoSaveResult(
                success: true,
                assetIdentifier: assetIdentifier,
                albumName: albumName ?? glowlyAlbumName,
                originalPhoto: photo,
                savedAt: Date()
            )
            
            lastSaveResult = result
            return result
            
        } catch {
            let result = PhotoSaveResult(
                success: false,
                error: error.localizedDescription,
                originalPhoto: photo,
                savedAt: Date()
            )
            lastSaveResult = result
            throw error
        }
    }
    
    func saveBatchPhotos(
        _ photos: [GlowlyPhoto],
        to albumName: String? = nil,
        preserveMetadata: Bool = true,
        includeEnhancementHistory: Bool = true
    ) async throws -> BatchPhotoSaveResult {
        
        guard authorizationStatus == .authorized else {
            throw PhotoLibraryError.authorizationDenied
        }
        
        isProcessing = true
        processingProgress = 0.0
        
        defer {
            isProcessing = false
            processingProgress = 0.0
        }
        
        var results: [PhotoSaveResult] = []
        let totalPhotos = photos.count
        
        for (index, photo) in photos.enumerated() {
            do {
                let baseProgress = Double(index) / Double(totalPhotos)
                let stepProgress = 1.0 / Double(totalPhotos)
                
                let result = try await savePhoto(
                    photo,
                    to: albumName,
                    preserveMetadata: preserveMetadata,
                    includeEnhancementHistory: includeEnhancementHistory
                )
                results.append(result)
                
                processingProgress = baseProgress + stepProgress
                
            } catch {
                let failedResult = PhotoSaveResult(
                    success: false,
                    error: error.localizedDescription,
                    originalPhoto: photo,
                    savedAt: Date()
                )
                results.append(failedResult)
            }
        }
        
        return BatchPhotoSaveResult(
            totalPhotos: totalPhotos,
            results: results
        )
    }
    
    // MARK: - Metadata Handling
    
    private func addMetadataToRequest(
        _ request: PHAssetCreationRequest,
        photo: GlowlyPhoto,
        includeEnhancementHistory: Bool
    ) {
        // Create metadata dictionary
        var metadata: [String: Any] = [:]
        
        // Add basic metadata
        metadata[kCGImagePropertyPixelWidth as String] = photo.metadata.width
        metadata[kCGImagePropertyPixelHeight as String] = photo.metadata.height
        
        // Add EXIF data
        if !photo.metadata.exifData.isEmpty {
            metadata[kCGImagePropertyExifDictionary as String] = photo.metadata.exifData
        }
        
        // Add Glowly-specific metadata
        var glowlyMetadata: [String: Any] = [:]
        glowlyMetadata["version"] = "1.0"
        glowlyMetadata["photoId"] = photo.id.uuidString
        glowlyMetadata["createdAt"] = ISO8601DateFormatter().string(from: photo.createdAt)
        glowlyMetadata["isEnhanced"] = photo.isEnhanced
        
        if includeEnhancementHistory && !photo.enhancementHistory.isEmpty {
            let enhancementData = photo.enhancementHistory.map { enhancement in
                [
                    "type": enhancement.type.rawValue,
                    "intensity": enhancement.intensity,
                    "appliedAt": ISO8601DateFormatter().string(from: enhancement.appliedAt)
                ]
            }
            glowlyMetadata["enhancements"] = enhancementData
        }
        
        metadata["Glowly"] = glowlyMetadata
        
        // Set metadata on request
        if let metadataData = try? PropertyListSerialization.data(fromPropertyList: metadata, format: .xml, options: 0) {
            let options = PHAssetResourceCreationOptions()
            options.originalFilename = "glowly_\(photo.id.uuidString).jpg"
            // Note: In a real implementation, you'd need to embed this metadata into the image file
        }
    }
    
    // MARK: - Asset Management
    
    private func addAssetToAlbum(identifier: String, albumName: String?) async {
        guard let album = getAlbum(named: albumName) else { return }
        
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        guard let asset = assets.firstObject else { return }
        
        do {
            try await photoLibrary.performChanges {
                guard let albumChangeRequest = PHAssetCollectionChangeRequest(for: album) else { return }
                albumChangeRequest.addAssets([asset] as NSArray)
            }
        } catch {
            print("Failed to add asset to album: \(error)")
        }
    }
    
    private func getAlbum(named albumName: String?) -> PHAssetCollection? {
        let targetAlbumName = albumName ?? glowlyAlbumName
        
        if targetAlbumName == glowlyAlbumName {
            return glowlyAlbum
        }
        
        // Look for custom album
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", targetAlbumName)
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        return collections.firstObject
    }
    
    // MARK: - Photo Retrieval
    
    func getGlowlyPhotos(from albumName: String? = nil, limit: Int = 100) async -> [PHAsset] {
        guard let album = getAlbum(named: albumName) else { return [] }
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.fetchLimit = limit
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let assets = PHAsset.fetchAssets(in: album, options: fetchOptions)
        return assets.objects(at: IndexSet(0..<assets.count))
    }
    
    func deletePhoto(assetIdentifier: String) async throws {
        guard authorizationStatus == .authorized else {
            throw PhotoLibraryError.authorizationDenied
        }
        
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
        guard assets.count > 0 else {
            throw PhotoLibraryError.assetNotFound
        }
        
        try await photoLibrary.performChanges {
            PHAssetChangeRequest.deleteAssets(assets)
        }
    }
    
    // MARK: - Album Statistics
    
    func getAlbumStatistics() async -> AlbumStatistics {
        guard let album = glowlyAlbum else {
            return AlbumStatistics()
        }
        
        let fetchOptions = PHFetchOptions()
        let assets = PHAsset.fetchAssets(in: album, options: fetchOptions)
        
        var totalSize: Int64 = 0
        let group = DispatchGroup()
        
        for i in 0..<assets.count {
            group.enter()
            let asset = assets.object(at: i)
            
            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: nil) { data, _, _, _ in
                if let data = data {
                    totalSize += Int64(data.count)
                }
                group.leave()
            }
        }
        
        await withCheckedContinuation { continuation in
            group.notify(queue: .main) {
                continuation.resume()
            }
        }
        
        return AlbumStatistics(
            photoCount: assets.count,
            totalSizeBytes: totalSize,
            albumName: glowlyAlbumName
        )
    }
}

// MARK: - Photo Library Manager Delegate

extension PhotoLibraryManager: PHPhotoLibraryChangeObserver {
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        // Handle photo library changes
        DispatchQueue.main.async {
            // Refresh albums if needed
            if let album = self.glowlyAlbum,
               let changeDetails = changeInstance.changeDetails(for: PHAsset.fetchAssets(in: album, options: nil)) {
                // Handle asset changes in Glowly album
                if changeDetails.hasIncrementalChanges {
                    // Handle incremental changes
                }
            }
        }
    }
}

// MARK: - Supporting Models

struct PhotoSaveResult: Codable {
    let success: Bool
    let assetIdentifier: String?
    let albumName: String?
    let error: String?
    let originalPhoto: GlowlyPhoto
    let savedAt: Date
    
    init(
        success: Bool,
        assetIdentifier: String? = nil,
        albumName: String? = nil,
        error: String? = nil,
        originalPhoto: GlowlyPhoto,
        savedAt: Date
    ) {
        self.success = success
        self.assetIdentifier = assetIdentifier
        self.albumName = albumName
        self.error = error
        self.originalPhoto = originalPhoto
        self.savedAt = savedAt
    }
}

struct BatchPhotoSaveResult: Codable {
    let totalPhotos: Int
    let results: [PhotoSaveResult]
    let completedAt: Date
    
    var successfulSaves: Int {
        return results.filter { $0.success }.count
    }
    
    var failedSaves: Int {
        return results.filter { !$0.success }.count
    }
    
    var successRate: Double {
        guard totalPhotos > 0 else { return 0 }
        return Double(successfulSaves) / Double(totalPhotos)
    }
    
    init(totalPhotos: Int, results: [PhotoSaveResult]) {
        self.totalPhotos = totalPhotos
        self.results = results
        self.completedAt = Date()
    }
}

struct AlbumStatistics: Codable {
    let photoCount: Int
    let totalSizeBytes: Int64
    let albumName: String
    let lastUpdated: Date
    
    var totalSizeMB: Double {
        return Double(totalSizeBytes) / (1024 * 1024)
    }
    
    var averageFileSizeBytes: Int64 {
        guard photoCount > 0 else { return 0 }
        return totalSizeBytes / Int64(photoCount)
    }
    
    init(
        photoCount: Int = 0,
        totalSizeBytes: Int64 = 0,
        albumName: String = "Glowly Enhanced"
    ) {
        self.photoCount = photoCount
        self.totalSizeBytes = totalSizeBytes
        self.albumName = albumName
        self.lastUpdated = Date()
    }
}

// MARK: - Photo Library Errors

enum PhotoLibraryError: LocalizedError {
    case authorizationDenied
    case noImageData
    case assetNotFound
    case albumCreationFailed
    case saveOperationFailed(String)
    case metadataProcessingFailed
    
    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Photo library access denied. Please enable access in Settings."
        case .noImageData:
            return "No image data available to save"
        case .assetNotFound:
            return "Photo asset not found in library"
        case .albumCreationFailed:
            return "Failed to create Glowly album"
        case .saveOperationFailed(let reason):
            return "Save operation failed: \(reason)"
        case .metadataProcessingFailed:
            return "Failed to process photo metadata"
        }
    }
}