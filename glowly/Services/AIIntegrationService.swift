//
//  AIIntegrationService.swift
//  Glowly
//
//  Central integration service for all AI-powered face detection and beauty enhancement features
//

import Foundation
import UIKit
import AVFoundation
import Combine

/// Central AI integration service coordinating all AI-powered features
@MainActor
final class AIIntegrationService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isInitialized = false
    @Published var initializationProgress: Float = 0.0
    @Published var isAnalyzing = false
    @Published var analysisProgress: Float = 0.0
    @Published var lastAnalysisResult: BeautyRecommendationResult?
    @Published var realTimeFaceResults: RealTimeFaceTrackingResult?
    @Published var performanceMetrics: AIPerformanceMetrics = AIPerformanceMetrics()
    
    // MARK: - Core Services
    private let coreMLService: CoreMLService
    private let visionService: VisionProcessingService
    private let beautyService: BeautyEnhancementService
    private let realTimeTracking: RealTimeFaceTrackingService
    private let modelManager: CoreMLModelManager
    
    // MARK: - Supporting Services
    private let analyticsService: AnalyticsService
    private let errorHandlingService: ErrorHandlingService
    private let userPreferencesService: UserPreferencesService
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var isRealTimeTrackingActive = false
    
    // MARK: - Initialization
    
    init(
        analyticsService: AnalyticsService = AnalyticsService.shared,
        errorHandlingService: ErrorHandlingService = ErrorHandlingService.shared,
        userPreferencesService: UserPreferencesService = UserPreferencesService.shared
    ) {
        // Initialize core AI services
        self.modelManager = CoreMLModelManager()
        self.visionService = VisionProcessingService()
        self.realTimeTracking = RealTimeFaceTrackingService()
        
        self.beautyService = BeautyEnhancementService(
            visionService: visionService,
            modelManager: modelManager
        )
        
        self.coreMLService = CoreMLService(
            modelManager: modelManager,
            visionService: visionService,
            beautyService: beautyService,
            realTimeFaceTracking: realTimeTracking
        )
        
        // Supporting services
        self.analyticsService = analyticsService
        self.errorHandlingService = errorHandlingService
        self.userPreferencesService = userPreferencesService
        
        setupBindings()
    }
    
    private func setupBindings() {
        // Bind initialization progress
        coreMLService.$loadingProgress
            .receive(on: DispatchQueue.main)
            .assign(to: &$initializationProgress)
        
        coreMLService.$isModelLoaded
            .receive(on: DispatchQueue.main)
            .assign(to: &$isInitialized)
        
        // Bind analysis progress
        beautyService.$isAnalyzing
            .receive(on: DispatchQueue.main)
            .assign(to: &$isAnalyzing)
        
        beautyService.$analysisProgress
            .receive(on: DispatchQueue.main)
            .assign(to: &$analysisProgress)
        
        beautyService.$lastAnalysisResult
            .receive(on: DispatchQueue.main)
            .assign(to: &$lastAnalysisResult)
        
        // Bind real-time tracking results
        realTimeTracking.faceTrackingResults
            .receive(on: DispatchQueue.main)
            .assign(to: &$realTimeFaceResults)
        
        // Monitor performance metrics
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updatePerformanceMetrics()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public API
    
    /// Initialize all AI services and models
    func initialize() async throws {
        guard !isInitialized else { return }
        
        do {
            analyticsService.trackUserAction(.aiServicesInitializationStarted)
            
            // Load all Core ML models
            try await coreMLService.loadModels()
            
            analyticsService.trackUserAction(.aiServicesInitializationCompleted, properties: [
                "initialization_time": initializationProgress,
                "models_loaded": coreMLService.availableModels.count
            ])
            
        } catch {
            analyticsService.trackError(.aiInitializationFailure, details: error.localizedDescription)
            errorHandlingService.handle(error, context: "AI Services Initialization")
            throw error
        }
    }
    
    /// Perform comprehensive AI-powered photo analysis
    func analyzePhoto(_ image: UIImage) async throws -> BeautyRecommendationResult {
        guard isInitialized else {
            throw AIIntegrationError.notInitialized
        }
        
        guard coreMLService.isImageSuitableForAnalysis(image) else {
            throw AIIntegrationError.unsuitableImage
        }
        
        do {
            let userProfile = userPreferencesService.currentUser?.profile
            let result = try await coreMLService.performComprehensiveAnalysis(image, userProfile: userProfile)
            
            // Track successful analysis
            analyticsService.trackUserAction(.photoAnalysisCompleted, properties: [
                "face_count": result.imageAnalysis.faceCount,
                "beauty_score": result.beautyAnalysis.overallScore,
                "confidence_score": result.confidenceScore,
                "processing_time": result.processingTime,
                "recommendations_count": result.recommendations.count
            ])
            
            return result
            
        } catch {
            analyticsService.trackError(.photoAnalysisFailure, details: error.localizedDescription)
            errorHandlingService.handle(error, context: "Photo Analysis")
            throw error
        }
    }
    
    /// Start real-time face tracking for camera preview
    func startRealTimeFaceTracking() {
        guard isInitialized else { return }
        
        coreMLService.startRealTimeFaceTracking()
        isRealTimeTrackingActive = true
        
        analyticsService.trackUserAction(.realTimeFaceTrackingStarted)
    }
    
    /// Stop real-time face tracking
    func stopRealTimeFaceTracking() {
        coreMLService.stopRealTimeFaceTracking()
        isRealTimeTrackingActive = false
        
        analyticsService.trackUserAction(.realTimeFaceTrackingStopped)
    }
    
    /// Update camera frame for real-time processing
    func processCameraFrame(_ sampleBuffer: CMSampleBuffer) {
        guard isRealTimeTrackingActive else { return }
        coreMLService.updateCameraFrame(sampleBuffer)
    }
    
    /// Get real-time enhancement suggestions for camera preview
    func getRealTimeEnhancementSuggestions() -> [RealTimeEnhancementSuggestion] {
        return coreMLService.getMostStableFace()?.enhancementSuggestions ?? []
    }
    
    /// Check if current camera view has a well-positioned face
    func hasWellPositionedFace() -> Bool {
        return coreMLService.hasWellPositionedFace()
    }
    
    /// Process multiple photos in batch
    func batchAnalyzePhotos(_ images: [UIImage]) async throws -> [BeautyRecommendationResult] {
        guard isInitialized else {
            throw AIIntegrationError.notInitialized
        }
        
        do {
            let userProfile = userPreferencesService.currentUser?.profile
            let results = try await coreMLService.batchAnalyzeImages(images, userProfile: userProfile)
            
            analyticsService.trackUserAction(.batchAnalysisCompleted, properties: [
                "batch_size": images.count,
                "successful_analyses": results.count,
                "average_processing_time": results.map { $0.processingTime }.reduce(0, +) / Double(results.count)
            ])
            
            return results
            
        } catch {
            analyticsService.trackError(.batchAnalysisFailure, details: error.localizedDescription)
            throw error
        }
    }
    
    /// Track enhancement effectiveness for machine learning
    func trackEnhancementEffectiveness(
        original: UIImage,
        enhanced: UIImage,
        appliedEnhancements: [Enhancement]
    ) async throws -> EffectivenessAnalysis {
        guard isInitialized else {
            throw AIIntegrationError.notInitialized
        }
        
        do {
            let effectiveness = try await coreMLService.trackEnhancementEffectiveness(
                original: original,
                enhanced: enhanced,
                appliedEnhancements: appliedEnhancements
            )
            
            analyticsService.trackUserAction(.enhancementEffectivenessTracked, properties: [
                "enhancement_count": appliedEnhancements.count,
                "overall_improvement": effectiveness.overallImprovement,
                "most_effective_enhancement": effectiveness.mostEffectiveEnhancement?.enhancementType.rawValue ?? "none"
            ])
            
            return effectiveness
            
        } catch {
            analyticsService.trackError(.effectivenessTrackingFailure, details: error.localizedDescription)
            throw error
        }
    }
    
    /// Provide user feedback on enhancement results
    func provideFeedback(_ feedback: EnhancementFeedback) {
        coreMLService.updateUserLearning(feedback: feedback)
        
        analyticsService.trackUserAction(.enhancementFeedback, properties: [
            "enhancement_type": feedback.enhancementType.rawValue,
            "satisfaction_score": feedback.satisfactionScore,
            "would_use_again": feedback.wouldUseAgain
        ])
    }
    
    /// Get personalized recommendations based on user history
    func getPersonalizedRecommendations(for image: UIImage) async throws -> [PersonalizedRecommendation] {
        guard isInitialized else {
            throw AIIntegrationError.notInitialized
        }
        
        do {
            let analysis = try await visionService.analyzeImage(image)
            let userProfile = userPreferencesService.currentUser?.profile
            
            return await beautyService.generatePersonalizedRecommendations(
                for: analysis,
                userProfile: userProfile
            )
            
        } catch {
            errorHandlingService.handle(error, context: "Personalized Recommendations")
            throw error
        }
    }
    
    /// Get user's recommendation history
    func getRecommendationHistory() -> [RecommendationHistory] {
        guard let userId = userPreferencesService.currentUser?.id else { return [] }
        return coreMLService.getRecommendationHistory(for: userId)
    }
    
    // MARK: - Model Management
    
    /// Get information about loaded AI models
    func getModelInformation() -> [MLModelInfo] {
        return coreMLService.getModelPerformanceInfo()
    }
    
    /// Optimize memory usage by unloading unused models
    func optimizeMemoryUsage() {
        coreMLService.optimizeMemoryUsage()
        
        analyticsService.trackUserAction(.memoryOptimizationPerformed)
    }
    
    /// Check if a specific feature is available
    func isFeatureAvailable(_ feature: AIFeature) -> Bool {
        switch feature {
        case .faceDetection:
            return isInitialized
        case .beautyAnalysis:
            return isInitialized && coreMLService.isModelAvailable("Beauty Enhancement")
        case .realTimeTracking:
            return isInitialized
        case .skinToneAnalysis:
            return isInitialized && coreMLService.isModelAvailable("Skin Tone Classifier")
        case .batchProcessing:
            return isInitialized
        case .enhancementLearning:
            return isInitialized
        }
    }
    
    // MARK: - Performance Monitoring
    
    private func updatePerformanceMetrics() {
        let modelInfo = getModelInformation()
        
        performanceMetrics = AIPerformanceMetrics(
            modelsLoaded: modelInfo.count,
            averageInferenceTime: modelInfo.compactMap { $0.averageInferenceTime }.reduce(0, +) / Double(modelInfo.count),
            memoryUsage: modelInfo.map { $0.memoryUsage }.reduce(0, +),
            realTimeTrackingFPS: realTimeTracking.processingFPS,
            isRealTimeActive: isRealTimeTrackingActive,
            lastAnalysisTime: lastAnalysisResult?.processingTime ?? 0
        )
    }
    
    // MARK: - Error Recovery
    
    /// Attempt to recover from AI service errors
    func recoverFromError() async {
        do {
            // Restart services if needed
            if !isInitialized {
                try await initialize()
            }
            
            // Optimize memory usage
            optimizeMemoryUsage()
            
            analyticsService.trackUserAction(.aiServiceRecoveryAttempted)
            
        } catch {
            analyticsService.trackError(.aiServiceRecoveryFailure, details: error.localizedDescription)
        }
    }
    
    // MARK: - Cleanup
    
    /// Clean up resources when no longer needed
    func cleanup() {
        stopRealTimeFaceTracking()
        coreMLService.unloadModels()
        cancellables.removeAll()
        
        analyticsService.trackUserAction(.aiServicesCleanup)
    }
}

// MARK: - Supporting Types

/// AI features that can be checked for availability
enum AIFeature: String, CaseIterable {
    case faceDetection = "face_detection"
    case beautyAnalysis = "beauty_analysis"
    case realTimeTracking = "real_time_tracking"
    case skinToneAnalysis = "skin_tone_analysis"
    case batchProcessing = "batch_processing"
    case enhancementLearning = "enhancement_learning"
    
    var displayName: String {
        switch self {
        case .faceDetection: return "Face Detection"
        case .beautyAnalysis: return "Beauty Analysis"
        case .realTimeTracking: return "Real-time Tracking"
        case .skinToneAnalysis: return "Skin Tone Analysis"
        case .batchProcessing: return "Batch Processing"
        case .enhancementLearning: return "Enhancement Learning"
        }
    }
}

/// Performance metrics for AI services
struct AIPerformanceMetrics: Codable {
    let modelsLoaded: Int
    let averageInferenceTime: TimeInterval
    let memoryUsage: Int64
    let realTimeTrackingFPS: Float
    let isRealTimeActive: Bool
    let lastAnalysisTime: TimeInterval
    
    init(
        modelsLoaded: Int = 0,
        averageInferenceTime: TimeInterval = 0,
        memoryUsage: Int64 = 0,
        realTimeTrackingFPS: Float = 0,
        isRealTimeActive: Bool = false,
        lastAnalysisTime: TimeInterval = 0
    ) {
        self.modelsLoaded = modelsLoaded
        self.averageInferenceTime = averageInferenceTime
        self.memoryUsage = memoryUsage
        self.realTimeTrackingFPS = realTimeTrackingFPS
        self.isRealTimeActive = isRealTimeActive
        self.lastAnalysisTime = lastAnalysisTime
    }
    
    var isPerformant: Bool {
        averageInferenceTime < 2.0 && realTimeTrackingFPS > 15.0
    }
    
    var memoryUsageMB: Double {
        Double(memoryUsage) / (1024 * 1024)
    }
}

/// Errors specific to AI integration
enum AIIntegrationError: LocalizedError {
    case notInitialized
    case unsuitableImage
    case featureNotAvailable(String)
    case resourceExhausted
    case deviceNotSupported
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "AI services are not initialized. Please wait for initialization to complete."
        case .unsuitableImage:
            return "The provided image is not suitable for AI analysis. Please use a clear, well-lit photo."
        case .featureNotAvailable(let feature):
            return "The feature '\(feature)' is not available on this device or is currently disabled."
        case .resourceExhausted:
            return "Insufficient system resources for AI processing. Please close other apps and try again."
        case .deviceNotSupported:
            return "This device does not support the required AI features."
        }
    }
}

// MARK: - Analytics Event Extensions

extension AnalyticsEvent {
    static let aiServicesInitializationStarted = AnalyticsEvent(name: "ai_services_initialization_started", category: .system)
    static let aiServicesInitializationCompleted = AnalyticsEvent(name: "ai_services_initialization_completed", category: .system)
    static let photoAnalysisCompleted = AnalyticsEvent(name: "photo_analysis_completed", category: .usage)
    static let realTimeFaceTrackingStarted = AnalyticsEvent(name: "real_time_face_tracking_started", category: .usage)
    static let realTimeFaceTrackingStopped = AnalyticsEvent(name: "real_time_face_tracking_stopped", category: .usage)
    static let batchAnalysisCompleted = AnalyticsEvent(name: "batch_analysis_completed", category: .usage)
    static let enhancementEffectivenessTracked = AnalyticsEvent(name: "enhancement_effectiveness_tracked", category: .usage)
    static let memoryOptimizationPerformed = AnalyticsEvent(name: "memory_optimization_performed", category: .system)
    static let aiServiceRecoveryAttempted = AnalyticsEvent(name: "ai_service_recovery_attempted", category: .system)
    static let aiServicesCleanup = AnalyticsEvent(name: "ai_services_cleanup", category: .system)
}

extension AnalyticsError {
    static let aiInitializationFailure = AnalyticsError(name: "ai_initialization_failure", category: .system)
    static let photoAnalysisFailure = AnalyticsError(name: "photo_analysis_failure", category: .usage)
    static let batchAnalysisFailure = AnalyticsError(name: "batch_analysis_failure", category: .usage)
    static let effectivenessTrackingFailure = AnalyticsError(name: "effectiveness_tracking_failure", category: .usage)
    static let aiServiceRecoveryFailure = AnalyticsError(name: "ai_service_recovery_failure", category: .system)
}