//
//  AIEnhancedEditViewModel.swift
//  Glowly
//
//  Enhanced edit view model integrating AI-powered face detection and beauty enhancement
//

import Foundation
import UIKit
import Combine

/// Enhanced edit view model with comprehensive AI integration
@MainActor
final class AIEnhancedEditViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentPhoto: GlowlyPhoto?
    @Published var currentImage: UIImage?
    @Published var enhancedImage: UIImage?
    @Published var appliedEnhancements: [Enhancement] = []
    
    // AI Analysis Results
    @Published var aiAnalysisResult: BeautyRecommendationResult?
    @Published var isAnalyzing = false
    @Published var analysisProgress: Float = 0.0
    
    // AI Recommendations
    @Published var aiRecommendations: [PersonalizedRecommendation] = []
    @Published var selectedRecommendations: Set<UUID> = []
    @Published var recommendationPreview: UIImage?
    
    // Real-time Analysis (for camera mode)
    @Published var realTimeFaceResults: RealTimeFaceTrackingResult?
    @Published var realTimeEnhancementSuggestions: [RealTimeEnhancementSuggestion] = []
    @Published var isRealTimeTrackingActive = false
    
    // User Interaction
    @Published var showingAIRecommendations = false
    @Published var showingEnhancementDetails = false
    @Published var selectedEnhancementType: EnhancementType?
    
    // Performance and Status
    @Published var aiPerformanceMetrics: AIPerformanceMetrics = AIPerformanceMetrics()
    @Published var processingStatus: ProcessingStatus = .idle
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    private let aiIntegrationService: AIIntegrationService
    private let imageProcessingService: ImageProcessingService
    private let photoService: PhotoService
    private let analyticsService: AnalyticsService
    private let errorHandlingService: ErrorHandlingService
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var originalImageForComparison: UIImage?
    
    // MARK: - Initialization
    
    init(
        photo: GlowlyPhoto? = nil,
        aiIntegrationService: AIIntegrationService = AIIntegrationService(),
        imageProcessingService: ImageProcessingService = ImageProcessingService.shared,
        photoService: PhotoService = PhotoService.shared,
        analyticsService: AnalyticsService = AnalyticsService.shared,
        errorHandlingService: ErrorHandlingService = ErrorHandlingService.shared
    ) {
        self.currentPhoto = photo
        self.aiIntegrationService = aiIntegrationService
        self.imageProcessingService = imageProcessingService
        self.photoService = photoService
        self.analyticsService = analyticsService
        self.errorHandlingService = errorHandlingService
        
        setupBindings()
        loadPhotoIfNeeded()
        initializeAIServices()
    }
    
    private func setupBindings() {
        // Bind AI service properties
        aiIntegrationService.$isAnalyzing
            .receive(on: DispatchQueue.main)
            .assign(to: &$isAnalyzing)
        
        aiIntegrationService.$analysisProgress
            .receive(on: DispatchQueue.main)
            .assign(to: &$analysisProgress)
        
        aiIntegrationService.$lastAnalysisResult
            .receive(on: DispatchQueue.main)
            .assign(to: &$aiAnalysisResult)
        
        aiIntegrationService.$realTimeFaceResults
            .receive(on: DispatchQueue.main)
            .assign(to: &$realTimeFaceResults)
        
        aiIntegrationService.$performanceMetrics
            .receive(on: DispatchQueue.main)
            .assign(to: &$aiPerformanceMetrics)
        
        // Update recommendations when analysis completes
        $aiAnalysisResult
            .compactMap { $0?.recommendations }
            .assign(to: &$aiRecommendations)
        
        // Update real-time suggestions
        $realTimeFaceResults
            .compactMap { $0?.primaryFace?.enhancementSuggestions }
            .assign(to: &$realTimeEnhancementSuggestions)
        
        // Track when real-time tracking is active
        $realTimeFaceResults
            .map { $0 != nil }
            .assign(to: &$isRealTimeTrackingActive)
    }
    
    private func loadPhotoIfNeeded() {
        if let photo = currentPhoto,
           let imageData = photo.originalImage ?? photo.enhancedImage,
           let image = UIImage(data: imageData) {
            currentImage = image
            originalImageForComparison = image
        }
    }
    
    private func initializeAIServices() {
        Task {
            do {
                await aiIntegrationService.initialize()
            } catch {
                errorMessage = error.localizedDescription
                errorHandlingService.handle(error, context: "AI Services Initialization")
            }
        }
    }
    
    // MARK: - AI Analysis Methods
    
    /// Perform comprehensive AI analysis of the current image
    func performAIAnalysis() async {
        guard let image = currentImage else {
            errorMessage = "No image selected for analysis"
            return
        }
        
        do {
            let result = try await aiIntegrationService.analyzePhoto(image)
            
            // Track analytics
            analyticsService.trackUserAction(.aiAnalysisRequested, properties: [
                "face_count": result.imageAnalysis.faceCount,
                "has_faces": result.imageAnalysis.hasFaces,
                "beauty_score": result.beautyAnalysis.overallScore
            ])
            
            // Show recommendations if high confidence
            if result.confidenceScore > 0.7 {
                showingAIRecommendations = true
            }
            
        } catch {
            errorMessage = error.localizedDescription
            errorHandlingService.handle(error, context: "AI Photo Analysis")
        }
    }
    
    /// Apply AI-recommended enhancements
    func applyAIRecommendations() async {
        guard let image = currentImage,
              !selectedRecommendations.isEmpty else { return }
        
        let selectedRecs = aiRecommendations.filter { selectedRecommendations.contains($0.id) }
        
        do {
            // Convert recommendations to enhancements
            let enhancements = selectedRecs.map { recommendation in
                Enhancement(
                    type: recommendation.enhancementType,
                    intensity: recommendation.recommendedIntensity,
                    aiGenerated: true
                )
            }
            
            // Apply enhancements
            let enhancedImage = try await imageProcessingService.applyEnhancements(
                to: image,
                enhancements: enhancements
            )
            
            self.enhancedImage = enhancedImage
            self.appliedEnhancements.append(contentsOf: enhancements)
            
            // Track effectiveness
            if let originalImage = originalImageForComparison {
                await trackEnhancementEffectiveness(
                    original: originalImage,
                    enhanced: enhancedImage,
                    enhancements: enhancements
                )
            }
            
            analyticsService.trackUserAction(.aiRecommendationsApplied, properties: [
                "recommendations_count": selectedRecs.count,
                "enhancement_types": selectedRecs.map { $0.enhancementType.rawValue }
            ])
            
        } catch {
            errorMessage = error.localizedDescription
            errorHandlingService.handle(error, context: "AI Enhancement Application")
        }
    }
    
    /// Preview AI recommendations without applying them
    func previewAIRecommendations() async {
        guard let image = currentImage,
              !selectedRecommendations.isEmpty else {
            recommendationPreview = nil
            return
        }
        
        let selectedRecs = aiRecommendations.filter { selectedRecommendations.contains($0.id) }
        
        do {
            let enhancements = selectedRecs.map { recommendation in
                Enhancement(
                    type: recommendation.enhancementType,
                    intensity: recommendation.recommendedIntensity * 0.7, // Lighter for preview
                    aiGenerated: true
                )
            }
            
            let previewImage = try await imageProcessingService.applyEnhancements(
                to: image,
                enhancements: enhancements
            )
            
            recommendationPreview = previewImage
            
        } catch {
            print("Preview generation failed: \(error)")
        }
    }
    
    // MARK: - Real-Time Tracking Methods
    
    /// Start real-time face tracking for camera mode
    func startRealTimeTracking() {
        aiIntegrationService.startRealTimeFaceTracking()
        
        analyticsService.trackUserAction(.realTimeTrackingStarted)
    }
    
    /// Stop real-time face tracking
    func stopRealTimeTracking() {
        aiIntegrationService.stopRealTimeFaceTracking()
        
        analyticsService.trackUserAction(.realTimeTrackingStopped)
    }
    
    /// Process camera frame for real-time analysis
    func processCameraFrame(_ sampleBuffer: CMSampleBuffer) {
        aiIntegrationService.processCameraFrame(sampleBuffer)
    }
    
    /// Check if current camera view has optimal face positioning
    func hasOptimalFacePositioning() -> Bool {
        return aiIntegrationService.hasWellPositionedFace()
    }
    
    // MARK: - Enhancement Management
    
    /// Apply a specific enhancement with custom intensity
    func applyEnhancement(_ type: EnhancementType, intensity: Float) async {
        guard let image = currentImage else { return }
        
        do {
            let enhancement = Enhancement(type: type, intensity: intensity)
            let enhancedImage = try await imageProcessingService.applyEnhancement(
                to: image,
                enhancement: enhancement
            )
            
            self.enhancedImage = enhancedImage
            self.appliedEnhancements.append(enhancement)
            
            analyticsService.trackUserAction(.manualEnhancementApplied, properties: [
                "enhancement_type": type.rawValue,
                "intensity": intensity
            ])
            
        } catch {
            errorMessage = error.localizedDescription
            errorHandlingService.handle(error, context: "Manual Enhancement")
        }
    }
    
    /// Remove the last applied enhancement
    func undoLastEnhancement() async {
        guard !appliedEnhancements.isEmpty,
              let originalImage = originalImageForComparison else { return }
        
        appliedEnhancements.removeLast()
        
        if appliedEnhancements.isEmpty {
            enhancedImage = originalImage
        } else {
            // Reapply remaining enhancements
            do {
                let reenhancedImage = try await imageProcessingService.applyEnhancements(
                    to: originalImage,
                    enhancements: appliedEnhancements
                )
                enhancedImage = reenhancedImage
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        
        analyticsService.trackUserAction(.enhancementUndone)
    }
    
    /// Reset all enhancements
    func resetEnhancements() {
        enhancedImage = originalImageForComparison
        appliedEnhancements.removeAll()
        selectedRecommendations.removeAll()
        recommendationPreview = nil
        
        analyticsService.trackUserAction(.enhancementsReset)
    }
    
    // MARK: - User Feedback
    
    /// Provide feedback on enhancement results
    func provideFeedback(for enhancementType: EnhancementType, satisfaction: Float, wouldUseAgain: Bool) {
        guard let userId = currentPhoto?.id else { return }
        
        let appliedEnhancement = appliedEnhancements.first { $0.type == enhancementType }
        
        let feedback = EnhancementFeedback(
            userId: userId,
            enhancementType: enhancementType,
            appliedIntensity: appliedEnhancement?.intensity ?? 0.5,
            satisfactionScore: satisfaction,
            visualImprovementRating: satisfaction, // Simplified
            wouldUseAgain: wouldUseAgain,
            imageAnalysisId: aiAnalysisResult?.imageAnalysis.faces.first?.id
        )
        
        aiIntegrationService.provideFeedback(feedback)
    }
    
    // MARK: - Save and Export
    
    /// Save the enhanced photo
    func saveEnhancedPhoto() async {
        guard let enhancedImage = enhancedImage,
              let originalPhoto = currentPhoto else { return }
        
        do {
            // Convert enhanced image to data
            let enhancedImageData = enhancedImage.jpegData(compressionQuality: 0.9)
            
            // Create updated photo
            var updatedPhoto = originalPhoto
            updatedPhoto.enhancedImage = enhancedImageData
            updatedPhoto.enhancementHistory.append(contentsOf: appliedEnhancements)
            
            // Save through photo service
            try await photoService.savePhoto(updatedPhoto)
            
            self.currentPhoto = updatedPhoto
            
            analyticsService.trackUserAction(.enhancedPhotoSaved, properties: [
                "enhancements_applied": appliedEnhancements.count,
                "ai_generated_count": appliedEnhancements.filter { $0.aiGenerated }.count
            ])
            
        } catch {
            errorMessage = error.localizedDescription
            errorHandlingService.handle(error, context: "Photo Saving")
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func trackEnhancementEffectiveness(
        original: UIImage,
        enhanced: UIImage,
        enhancements: [Enhancement]
    ) async {
        do {
            let effectiveness = try await aiIntegrationService.trackEnhancementEffectiveness(
                original: original,
                enhanced: enhanced,
                appliedEnhancements: enhancements
            )
            
            print("Enhancement effectiveness tracked: \(effectiveness.overallImprovement)")
            
        } catch {
            print("Failed to track enhancement effectiveness: \(error)")
        }
    }
    
    // MARK: - Computed Properties
    
    var hasAIRecommendations: Bool {
        !aiRecommendations.isEmpty
    }
    
    var selectedRecommendationsCount: Int {
        selectedRecommendations.count
    }
    
    var canApplyRecommendations: Bool {
        !selectedRecommendations.isEmpty && currentImage != nil
    }
    
    var hasEnhancements: Bool {
        !appliedEnhancements.isEmpty
    }
    
    var displayImage: UIImage? {
        enhancedImage ?? currentImage
    }
    
    var beautyScore: Float? {
        aiAnalysisResult?.beautyAnalysis.overallScore
    }
    
    var faceCount: Int {
        aiAnalysisResult?.imageAnalysis.faceCount ?? 0
    }
    
    var analysisConfidence: Float? {
        aiAnalysisResult?.confidenceScore
    }
}

// MARK: - Analytics Extensions

extension AnalyticsEvent {
    static let aiAnalysisRequested = AnalyticsEvent(name: "ai_analysis_requested", category: .usage)
    static let aiRecommendationsApplied = AnalyticsEvent(name: "ai_recommendations_applied", category: .usage)
    static let realTimeTrackingStarted = AnalyticsEvent(name: "real_time_tracking_started", category: .usage)
    static let realTimeTrackingStopped = AnalyticsEvent(name: "real_time_tracking_stopped", category: .usage)
    static let manualEnhancementApplied = AnalyticsEvent(name: "manual_enhancement_applied", category: .usage)
    static let enhancementUndone = AnalyticsEvent(name: "enhancement_undone", category: .usage)
    static let enhancementsReset = AnalyticsEvent(name: "enhancements_reset", category: .usage)
    static let enhancedPhotoSaved = AnalyticsEvent(name: "enhanced_photo_saved", category: .usage)
}