//
//  EditViewModel.swift
//  Glowly
//
//  ViewModel for the photo editing screen
//

import Foundation
import SwiftUI

@MainActor
final class EditViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var originalPhoto: GlowlyPhoto
    @Published var currentImage: UIImage?
    @Published var previewImage: UIImage?
    @Published var selectedEnhancement: EnhancementType?
    @Published var enhancementIntensity: Float = 0.5
    @Published var appliedEnhancements: [Enhancement] = []
    @Published var isProcessing = false
    @Published var processingProgress: Float = 0.0
    @Published var showingPresets = false
    @Published var selectedPreset: EnhancementPreset?
    @Published var availablePresets: [EnhancementPreset] = []
    @Published var showingExportOptions = false
    @Published var editHistory: [EditHistoryItem] = []
    @Published var canUndo: Bool = false
    @Published var canRedo: Bool = false
    
    // MARK: - Error Handling
    @Published var errorMessage: String?
    @Published var showingError = false
    
    // MARK: - Dependencies
    @Inject private var imageProcessingService: ImageProcessingServiceProtocol
    @Inject private var photoRepository: PhotoRepositoryProtocol
    @Inject private var photoService: PhotoServiceProtocol
    @Inject private var coreMLService: CoreMLServiceProtocol
    @Inject private var userPreferencesService: UserPreferencesServiceProtocol
    @Inject private var analyticsService: AnalyticsServiceProtocol
    @Inject private var errorHandlingService: ErrorHandlingServiceProtocol
    
    // MARK: - Enhancement Categories
    private var basicEnhancements: [EnhancementType] {
        EnhancementType.allCases.filter { $0.category == .basic }
    }
    
    private var beautyEnhancements: [EnhancementType] {
        EnhancementType.allCases.filter { $0.category == .beauty }
    }
    
    private var aiEnhancements: [EnhancementType] {
        EnhancementType.allCases.filter { $0.category == .ai }
    }
    
    var enhancementCategories: [EnhancementCategory] {
        EnhancementCategory.allCases
    }
    
    // MARK: - Computed Properties
    var hasChanges: Bool {
        !appliedEnhancements.isEmpty
    }
    
    var canApplyEnhancement: Bool {
        !isProcessing && selectedEnhancement != nil
    }
    
    var totalProcessingTime: TimeInterval {
        appliedEnhancements.reduce(0) { $0 + $1.processingTime }
    }
    
    // MARK: - Initialization
    init(photo: GlowlyPhoto) {
        self.originalPhoto = photo
        
        // Load current image
        if let imageData = photo.enhancedImage ?? photo.originalImage {
            self.currentImage = UIImage(data: imageData)
            self.previewImage = self.currentImage
        }
        
        // Load existing enhancements
        self.appliedEnhancements = photo.enhancementHistory
        
        // Load presets
        self.availablePresets = loadEnhancementPresets()
        
        Task {
            await trackScreenView()
        }
    }
    
    // MARK: - Enhancement Application
    
    func selectEnhancement(_ enhancement: EnhancementType) {
        selectedEnhancement = enhancement
        enhancementIntensity = enhancement.defaultIntensity
        
        Task {
            await generatePreview()
        }
    }
    
    func updateEnhancementIntensity(_ intensity: Float) {
        enhancementIntensity = intensity
        
        Task {
            await generatePreview()
        }
    }
    
    private func generatePreview() async {
        guard let enhancement = selectedEnhancement,
              let image = currentImage else {
            return
        }
        
        do {
            let enhancementToApply = Enhancement(
                type: enhancement,
                intensity: enhancementIntensity
            )
            
            previewImage = try await imageProcessingService.generatePreview(
                image,
                with: enhancementToApply,
                intensity: enhancementIntensity
            )
            
        } catch {
            await handleError(error, context: "Generating preview for \(enhancement.displayName)")
        }
    }
    
    func applyCurrentEnhancement() async {
        guard let enhancement = selectedEnhancement,
              let image = currentImage else {
            return
        }
        
        isProcessing = true
        processingProgress = 0.0
        
        let startTime = Date()
        
        do {
            let enhancementToApply = Enhancement(
                type: enhancement,
                intensity: enhancementIntensity,
                appliedAt: Date()
            )
            
            // Apply enhancement
            let enhancedImage = try await imageProcessingService.applyEnhancement(
                enhancementToApply,
                to: image
            )
            
            let processingTime = Date().timeIntervalSince(startTime)
            
            // Create enhancement with processing time
            let completedEnhancement = Enhancement(
                id: enhancementToApply.id,
                type: enhancement,
                intensity: enhancementIntensity,
                parameters: enhancementToApply.parameters,
                appliedAt: enhancementToApply.appliedAt,
                processingTime: processingTime,
                aiGenerated: enhancement.category == .ai
            )
            
            // Save to history for undo/redo
            addToEditHistory()
            
            // Update state
            currentImage = enhancedImage
            previewImage = enhancedImage
            appliedEnhancements.append(completedEnhancement)
            
            // Save to repository
            await saveCurrentState()
            
            // Track analytics
            await analyticsService.trackEnhancementUsage(enhancement, intensity: enhancementIntensity)
            
            // Clear selection
            selectedEnhancement = nil
            
        } catch {
            await handleError(error, context: "Applying \(enhancement.displayName)")
        }
        
        isProcessing = false
        processingProgress = 0.0
    }
    
    // MARK: - Presets
    
    func applyPreset(_ preset: EnhancementPreset) async {
        guard let image = currentImage else { return }
        
        isProcessing = true
        processingProgress = 0.0
        selectedPreset = preset
        
        let startTime = Date()
        
        do {
            // Save to history for undo/redo
            addToEditHistory()
            
            // Apply all enhancements in preset
            let enhancedImage = try await imageProcessingService.processImage(
                image,
                with: preset.enhancements
            )
            
            let processingTime = Date().timeIntervalSince(startTime)
            
            // Update state
            currentImage = enhancedImage
            previewImage = enhancedImage
            appliedEnhancements.append(contentsOf: preset.enhancements)
            
            // Save to repository
            await saveCurrentState()
            
            // Track analytics
            await analyticsService.trackEvent(
                AnalyticsEvent(name: "preset_applied", category: .enhancement),
                parameters: [
                    "preset_name": preset.name,
                    "preset_category": preset.category.rawValue,
                    "processing_time": processingTime,
                    "enhancement_count": preset.enhancements.count
                ]
            )
            
        } catch {
            await handleError(error, context: "Applying preset \(preset.name)")
        }
        
        isProcessing = false
        processingProgress = 0.0
        showingPresets = false
        selectedPreset = nil
    }
    
    // MARK: - History Management
    
    private func addToEditHistory() {
        guard let image = currentImage else { return }
        
        let historyItem = EditHistoryItem(
            image: image,
            enhancements: appliedEnhancements,
            timestamp: Date()
        )
        
        editHistory.append(historyItem)
        updateUndoRedoState()
    }
    
    func undo() {
        guard canUndo, editHistory.count > 1 else { return }
        
        // Remove current state and go back to previous
        editHistory.removeLast()
        
        if let previousState = editHistory.last {
            currentImage = previousState.image
            previewImage = previousState.image
            appliedEnhancements = previousState.enhancements
        }
        
        updateUndoRedoState()
        
        Task {
            await saveCurrentState()
            await analyticsService.trackEvent(
                AnalyticsEvent(name: "edit_undo", category: .enhancement)
            )
        }
    }
    
    func redo() {
        // Redo functionality would require a more complex history management system
        // For MVP, we'll skip this feature
    }
    
    private func updateUndoRedoState() {
        canUndo = editHistory.count > 1
        canRedo = false // For MVP
    }
    
    // MARK: - Reset and Save
    
    func resetToOriginal() async {
        guard let imageData = originalPhoto.originalImage,
              let originalImage = UIImage(data: imageData) else {
            return
        }
        
        // Save to history
        addToEditHistory()
        
        // Reset state
        currentImage = originalImage
        previewImage = originalImage
        appliedEnhancements.removeAll()
        selectedEnhancement = nil
        
        // Save to repository
        await saveCurrentState()
        
        await analyticsService.trackEvent(
            AnalyticsEvent(name: "edit_reset", category: .enhancement)
        )
    }
    
    private func saveCurrentState() async {
        guard let image = currentImage else { return }
        
        do {
            let imageData = photoService.imageToData(image, quality: 0.9)
            
            var updatedPhoto = originalPhoto
            updatedPhoto = GlowlyPhoto(
                id: originalPhoto.id,
                originalAssetIdentifier: originalPhoto.originalAssetIdentifier,
                originalImage: originalPhoto.originalImage,
                enhancedImage: imageData,
                thumbnailImage: originalPhoto.thumbnailImage,
                createdAt: originalPhoto.createdAt,
                updatedAt: Date(),
                metadata: originalPhoto.metadata,
                enhancementHistory: appliedEnhancements
            )
            
            try await photoRepository.updatePhoto(updatedPhoto)
            originalPhoto = updatedPhoto
            
        } catch {
            await handleError(error, context: "Saving current state")
        }
    }
    
    // MARK: - Export
    
    func exportPhoto() async {
        showingExportOptions = true
    }
    
    func saveToLibrary() async {
        guard let image = currentImage else { return }
        
        do {
            let photoToSave = GlowlyPhoto(
                originalImage: photoService.imageToData(image),
                enhancedImage: photoService.imageToData(image),
                metadata: originalPhoto.metadata,
                enhancementHistory: appliedEnhancements
            )
            
            let success = try await photoService.savePhoto(photoToSave, toLibrary: true)
            
            if success {
                await analyticsService.trackPhotoExport(
                    format: userPreferencesService.exportFormat,
                    quality: userPreferencesService.preferredQuality,
                    success: true
                )
                
                // Show success feedback
                print("Photo saved to library successfully")
            }
            
        } catch {
            await handleError(error, context: "Saving to photo library")
            await analyticsService.trackPhotoExport(
                format: userPreferencesService.exportFormat,
                quality: userPreferencesService.preferredQuality,
                success: false
            )
        }
    }
    
    // MARK: - Helper Methods
    
    func getEnhancementsForCategory(_ category: EnhancementCategory) -> [EnhancementType] {
        switch category {
        case .basic:
            return basicEnhancements
        case .beauty:
            return beautyEnhancements
        case .ai:
            return aiEnhancements
        }
    }
    
    private func loadEnhancementPresets() -> [EnhancementPreset] {
        // This would typically load from a data source
        // For MVP, return some sample presets
        return [
            EnhancementPreset(
                name: "Natural Glow",
                description: "Subtle enhancement for a natural look",
                enhancements: [
                    Enhancement(type: .skinSmoothing, intensity: 0.3),
                    Enhancement(type: .eyeBrightening, intensity: 0.2),
                    Enhancement(type: .brightness, intensity: 0.1)
                ],
                category: .natural
            ),
            EnhancementPreset(
                name: "Glamour Shot",
                description: "Full enhancement for stunning photos",
                enhancements: [
                    Enhancement(type: .skinSmoothing, intensity: 0.5),
                    Enhancement(type: .eyeBrightening, intensity: 0.4),
                    Enhancement(type: .teethWhitening, intensity: 0.3),
                    Enhancement(type: .contrast, intensity: 0.2)
                ],
                isPremium: true,
                category: .glamour
            )
        ]
    }
    
    private func trackScreenView() async {
        await analyticsService.trackScreenView("photo_edit")
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
}

// MARK: - EditHistoryItem

struct EditHistoryItem {
    let id = UUID()
    let image: UIImage
    let enhancements: [Enhancement]
    let timestamp: Date
}