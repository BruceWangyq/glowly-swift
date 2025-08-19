//
//  HomeViewModel.swift
//  Glowly
//
//  ViewModel for the home screen
//

import Foundation
import SwiftUI
import PhotosUI

@MainActor
final class HomeViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var recentPhotos: [GlowlyPhoto] = []
    @Published var isLoading = false
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var showingImagePicker = false
    @Published var showingCamera = false
    @Published var processingStatus: ProcessingStatus = .completed
    @Published var errorMessage: String?
    @Published var showingError = false
    
    // MARK: - Dependencies
    @Inject private var photoRepository: PhotoRepositoryProtocol
    @Inject private var photoService: PhotoServiceProtocol
    @Inject private var imageProcessingService: ImageProcessingServiceProtocol
    @Inject private var coreMLService: CoreMLServiceProtocol
    @Inject private var userPreferencesService: UserPreferencesServiceProtocol
    @Inject private var analyticsService: AnalyticsServiceProtocol
    @Inject private var errorHandlingService: ErrorHandlingServiceProtocol
    
    // MARK: - Computed Properties
    var hasPhotos: Bool {
        !recentPhotos.isEmpty
    }
    
    var canProcessPhotos: Bool {
        coreMLService.isModelLoaded && !isLoading
    }
    
    // MARK: - Initialization
    init() {
        Task {
            await loadInitialData()
        }
    }
    
    // MARK: - Data Loading
    
    private func loadInitialData() async {
        isLoading = true
        
        do {
            // Load recent photos
            recentPhotos = try await photoRepository.getRecentPhotos(limit: 20)
            
            // Track screen view
            await analyticsService.trackScreenView("home")
            
        } catch {
            await handleError(error, context: "Loading initial data")
        }
        
        isLoading = false
    }
    
    func refreshData() async {
        await loadInitialData()
    }
    
    // MARK: - Photo Import
    
    func importPhotoFromLibrary() {
        showingImagePicker = true
        Task {
            await analyticsService.trackEvent(
                AnalyticsEvent(name: "photo_import_started", category: .photo),
                parameters: ["source": "library"]
            )
        }
    }
    
    func importPhotoFromCamera() {
        showingCamera = true
        Task {
            await analyticsService.trackEvent(
                AnalyticsEvent(name: "photo_import_started", category: .photo),
                parameters: ["source": "camera"]
            )
        }
    }
    
    func handleSelectedPhoto(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        isLoading = true
        processingStatus = .processing
        
        do {
            // Load image data from PhotosPickerItem
            guard let imageData = try await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: imageData) else {
                throw PhotoServiceError.invalidImageData
            }
            
            // Create photo object
            let photo = try await createPhotoFromImage(uiImage, source: .photoLibrary)
            
            // Save to repository
            try await photoRepository.savePhoto(photo)
            
            // Update UI
            recentPhotos.insert(photo, at: 0)
            
            // Apply auto-enhancement if enabled
            if userPreferencesService.isAutoEnhanceEnabled {
                await autoEnhancePhoto(photo)
            }
            
            // Track success
            await analyticsService.trackPhotoImport(source: .photoLibrary, success: true)
            
        } catch {
            await handleError(error, context: "Importing photo from library")
            await analyticsService.trackPhotoImport(source: .photoLibrary, success: false)
        }
        
        isLoading = false
        processingStatus = .completed
        selectedPhotoItem = nil
    }
    
    private func createPhotoFromImage(_ image: UIImage, source: PhotoSource) async throws -> GlowlyPhoto {
        // Extract metadata
        let metadata = photoService.extractMetadata(from: image)
        
        // Generate thumbnail
        let thumbnail = await photoService.generateThumbnail(for: image)
        
        // Convert images to data
        let originalImageData = photoService.imageToData(image, quality: 0.9)
        let thumbnailData = thumbnail.flatMap { photoService.imageToData($0, quality: 0.7) }
        
        // Detect faces if Core ML is available
        var metadataWithFaces = metadata
        if coreMLService.isModelLoaded {
            do {
                let faces = try await coreMLService.detectFaces(in: image)
                metadataWithFaces = PhotoMetadata(
                    width: metadata.width,
                    height: metadata.height,
                    fileSize: metadata.fileSize,
                    format: metadata.format,
                    colorSpace: metadata.colorSpace,
                    exifData: metadata.exifData,
                    faceDetectionResults: faces
                )
            } catch {
                // Face detection failed, continue without faces
                print("Face detection failed: \(error)")
            }
        }
        
        return GlowlyPhoto(
            originalImage: originalImageData,
            thumbnailImage: thumbnailData,
            metadata: metadataWithFaces
        )
    }
    
    // MARK: - Auto Enhancement
    
    private func autoEnhancePhoto(_ photo: GlowlyPhoto) async {
        guard let imageData = photo.originalImage,
              let uiImage = UIImage(data: imageData) else {
            return
        }
        
        do {
            // Generate personalized enhancements
            let enhancements = try await coreMLService.generatePersonalizedEnhancements(
                for: uiImage,
                skinTone: nil // Would get from user profile
            )
            
            // Apply enhancements
            let enhancedImage = try await imageProcessingService.processImage(uiImage, with: enhancements)
            let enhancedImageData = photoService.imageToData(enhancedImage, quality: 0.9)
            
            // Update photo with enhanced version
            var updatedPhoto = photo
            updatedPhoto = GlowlyPhoto(
                id: photo.id,
                originalAssetIdentifier: photo.originalAssetIdentifier,
                originalImage: photo.originalImage,
                enhancedImage: enhancedImageData,
                thumbnailImage: photo.thumbnailImage,
                createdAt: photo.createdAt,
                updatedAt: Date(),
                metadata: photo.metadata,
                enhancementHistory: enhancements
            )
            
            // Save updated photo
            try await photoRepository.updatePhoto(updatedPhoto)
            
            // Update UI
            if let index = recentPhotos.firstIndex(where: { $0.id == photo.id }) {
                recentPhotos[index] = updatedPhoto
            }
            
            // Track enhancement
            for enhancement in enhancements {
                await analyticsService.trackEnhancementUsage(enhancement.type, intensity: enhancement.intensity)
            }
            
        } catch {
            await handleError(error, context: "Auto-enhancing photo")
        }
    }
    
    // MARK: - Photo Actions
    
    func deletePhoto(_ photo: GlowlyPhoto) async {
        do {
            try await photoRepository.deletePhoto(id: photo.id)
            recentPhotos.removeAll { $0.id == photo.id }
            
            await analyticsService.trackEvent(
                AnalyticsEvent(name: "photo_deleted", category: .photo)
            )
            
        } catch {
            await handleError(error, context: "Deleting photo")
        }
    }
    
    func sharePhoto(_ photo: GlowlyPhoto) async {
        guard let imageData = photo.enhancedImage ?? photo.originalImage,
              let image = UIImage(data: imageData) else {
            return
        }
        
        // This would typically trigger a share sheet
        await analyticsService.trackEvent(
            AnalyticsEvent(name: "photo_shared", category: .photo),
            parameters: ["has_enhancement": photo.enhancedImage != nil]
        )
    }
    
    func saveToLibrary(_ photo: GlowlyPhoto) async {
        do {
            let success = try await photoService.savePhoto(photo, toLibrary: true)
            
            if success {
                await analyticsService.trackPhotoExport(
                    format: userPreferencesService.exportFormat,
                    quality: userPreferencesService.preferredQuality,
                    success: true
                )
                
                // Show success feedback (would typically show toast/alert)
                print("Photo saved to library successfully")
            }
            
        } catch {
            await handleError(error, context: "Saving photo to library")
            await analyticsService.trackPhotoExport(
                format: userPreferencesService.exportFormat,
                quality: userPreferencesService.preferredQuality,
                success: false
            )
        }
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: Error, context: String) async {
        await errorHandlingService.logError(error, context: context)
        
        let action = await errorHandlingService.handleError(error, context: context)
        
        switch action {
        case .showUserError(let userError):
            await showError(userError.message)
        case .silent:
            break
        default:
            await showError("An unexpected error occurred. Please try again.")
        }
    }
    
    @MainActor
    private func showError(_ message: String) async {
        errorMessage = message
        showingError = true
    }
    
    func clearError() {
        errorMessage = nil
        showingError = false
    }
    
    // MARK: - Helper Methods
    
    func formatPhotoDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    func getPhotoSize(_ photo: GlowlyPhoto) -> String {
        let imageData = photo.enhancedImage ?? photo.originalImage
        guard let data = imageData else { return "Unknown" }
        
        let bytes = data.count
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}