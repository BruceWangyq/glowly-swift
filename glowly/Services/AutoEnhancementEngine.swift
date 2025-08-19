//
//  AutoEnhancementEngine.swift
//  Glowly
//
//  AI-powered one-tap auto enhancement engine with intelligent analysis and processing
//

import Foundation
import UIKit
import CoreML
import Vision
import Combine
import CoreImage

/// Protocol for auto enhancement operations
protocol AutoEnhancementEngineProtocol {
    func analyzeAndEnhance(image: UIImage, mode: EnhancementMode) async throws -> AutoEnhancementResult
    func previewEnhancement(image: UIImage, mode: EnhancementMode) async throws -> EnhancementPreview
    func applyCustomEnhancement(image: UIImage, profile: CustomEnhancementProfile) async throws -> AutoEnhancementResult
    func learnFromUserFeedback(result: AutoEnhancementResult, feedback: UserEnhancementFeedback)
}

/// Core auto enhancement engine with AI-powered intelligence
@MainActor
final class AutoEnhancementEngine: AutoEnhancementEngineProtocol, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isProcessing = false
    @Published var processingProgress: Float = 0.0
    @Published var currentMode: EnhancementMode = .natural
    @Published var lastResult: AutoEnhancementResult?
    @Published var previewCache: [String: EnhancementPreview] = [:]
    
    // MARK: - Dependencies
    private let beautyService: BeautyEnhancementService
    private let visionService: VisionProcessingService
    private let imageProcessor: ImageProcessingService
    private let userPreferences: UserPreferencesService
    private let analytics: AnalyticsService
    
    // MARK: - Private Properties
    private var enhancementProfiles: [EnhancementMode: EnhancementProfile] = [:]
    private var customProfiles: [UUID: CustomEnhancementProfile] = [:]
    private var learningData: EnhancementLearningSystem
    private var cancellables = Set<AnyCancellable>()
    
    // Core Image context for processing
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    
    // MARK: - Initialization
    
    init(
        beautyService: BeautyEnhancementService,
        visionService: VisionProcessingService = VisionProcessingService(),
        imageProcessor: ImageProcessingService = ImageProcessingService(),
        userPreferences: UserPreferencesService = UserPreferencesService.shared,
        analytics: AnalyticsService = AnalyticsService.shared
    ) {
        self.beautyService = beautyService
        self.visionService = visionService
        self.imageProcessor = imageProcessor
        self.userPreferences = userPreferences
        self.analytics = analytics
        self.learningData = EnhancementLearningSystem()
        
        setupEnhancementProfiles()
        setupLearningSystem()
    }
    
    // MARK: - Main Enhancement Methods
    
    /// Analyze image and apply one-tap enhancement
    func analyzeAndEnhance(image: UIImage, mode: EnhancementMode) async throws -> AutoEnhancementResult {
        isProcessing = true
        processingProgress = 0.0
        currentMode = mode
        
        defer {
            isProcessing = false
            processingProgress = 0.0
        }
        
        let startTime = Date()
        
        do {
            // Step 1: Comprehensive image analysis
            let analysis = try await performIntelligentAnalysis(image: image)
            processingProgress = 0.2
            
            // Step 2: Generate enhancement strategy
            let strategy = await generateEnhancementStrategy(analysis: analysis, mode: mode)
            processingProgress = 0.4
            
            // Step 3: Apply enhancements with real-time feedback
            let enhancedImage = try await applyEnhancementsPipeline(
                image: image,
                strategy: strategy,
                progressCallback: { progress in
                    Task { @MainActor in
                        self.processingProgress = 0.4 + (progress * 0.5)
                    }
                }
            )
            processingProgress = 0.9
            
            // Step 4: Generate before/after analysis
            let effectivenessAnalysis = try await analyzeEnhancementEffectiveness(
                original: image,
                enhanced: enhancedImage,
                strategy: strategy
            )
            processingProgress = 1.0
            
            let result = AutoEnhancementResult(
                originalImage: image,
                enhancedImage: enhancedImage,
                mode: mode,
                appliedEnhancements: strategy.enhancements,
                analysis: analysis,
                effectiveness: effectivenessAnalysis,
                processingTime: Date().timeIntervalSince(startTime),
                confidence: strategy.confidenceScore
            )
            
            // Cache result and update learning
            lastResult = result
            await updateLearningSystem(result: result)
            await trackAnalytics(result: result)
            
            return result
            
        } catch {
            analytics.trackError(.autoEnhancementFailure, details: error.localizedDescription)
            throw AutoEnhancementError.processingFailed(error.localizedDescription)
        }
    }
    
    /// Generate real-time preview of enhancement
    func previewEnhancement(image: UIImage, mode: EnhancementMode) async throws -> EnhancementPreview {
        let cacheKey = "\(image.hash)-\(mode.rawValue)"
        
        // Check cache first
        if let cachedPreview = previewCache[cacheKey] {
            return cachedPreview
        }
        
        // Generate quick analysis for preview
        let quickAnalysis = try await performQuickAnalysis(image: image)
        let previewStrategy = await generatePreviewStrategy(analysis: quickAnalysis, mode: mode)
        
        // Apply lightweight enhancements for preview
        let previewImage = try await applyPreviewEnhancements(
            image: image,
            strategy: previewStrategy
        )
        
        let preview = EnhancementPreview(
            previewImage: previewImage,
            mode: mode,
            estimatedImprovements: previewStrategy.estimatedImprovements,
            confidence: previewStrategy.confidenceScore,
            estimatedProcessingTime: previewStrategy.estimatedFullProcessingTime
        )
        
        // Cache preview
        previewCache[cacheKey] = preview
        
        return preview
    }
    
    /// Apply custom enhancement profile
    func applyCustomEnhancement(image: UIImage, profile: CustomEnhancementProfile) async throws -> AutoEnhancementResult {
        let analysis = try await performIntelligentAnalysis(image: image)
        
        // Adapt custom profile to image characteristics
        let adaptedProfile = await adaptCustomProfile(profile, to: analysis)
        
        let enhancedImage = try await applyCustomEnhancements(
            image: image,
            profile: adaptedProfile,
            analysis: analysis
        )
        
        let effectiveness = try await analyzeEnhancementEffectiveness(
            original: image,
            enhanced: enhancedImage,
            strategy: EnhancementStrategy(from: adaptedProfile)
        )
        
        return AutoEnhancementResult(
            originalImage: image,
            enhancedImage: enhancedImage,
            mode: .custom,
            appliedEnhancements: adaptedProfile.enhancements,
            analysis: analysis,
            effectiveness: effectiveness,
            processingTime: Date().timeIntervalSince1970,
            confidence: adaptedProfile.confidence
        )
    }
    
    /// Learn from user feedback to improve future enhancements
    func learnFromUserFeedback(result: AutoEnhancementResult, feedback: UserEnhancementFeedback) {
        learningData.processFeedback(result: result, feedback: feedback)
        
        // Update enhancement profiles based on learning
        updateEnhancementProfiles(from: learningData)
        
        analytics.trackUserAction(.enhancementFeedback, properties: [
            "mode": result.mode.rawValue,
            "satisfaction": feedback.satisfaction,
            "naturalness": feedback.naturalness,
            "would_use_again": feedback.wouldUseAgain
        ])
    }
    
    // MARK: - Private Analysis Methods
    
    private func performIntelligentAnalysis(image: UIImage) async throws -> ComprehensiveImageAnalysis {
        // Get base analysis from vision service
        let baseAnalysis = try await visionService.analyzeImage(image)
        
        // Enhanced beauty analysis
        let beautyAnalysis = try await beautyService.calculateBeautyScore(for: image)
        
        // Photo characteristics analysis
        let photoCharacteristics = try await analyzePhotoCharacteristics(image: image)
        
        // Enhancement opportunity analysis
        let opportunities = await analyzeEnhancementOpportunities(
            baseAnalysis: baseAnalysis,
            beautyAnalysis: beautyAnalysis,
            characteristics: photoCharacteristics
        )
        
        return ComprehensiveImageAnalysis(
            baseAnalysis: baseAnalysis,
            beautyAnalysis: beautyAnalysis,
            photoCharacteristics: photoCharacteristics,
            enhancementOpportunities: opportunities
        )
    }
    
    private func performQuickAnalysis(image: UIImage) async throws -> QuickImageAnalysis {
        // Lightweight analysis for preview generation
        let faces = try await visionService.detectFaces(in: image)
        let imageQuality = await imageProcessor.assessImageQuality(image)
        
        return QuickImageAnalysis(
            hasFace: !faces.isEmpty,
            primaryFace: faces.first,
            imageQuality: imageQuality,
            sceneType: await detectSceneType(image: image)
        )
    }
    
    private func analyzePhotoCharacteristics(image: UIImage) async throws -> PhotoCharacteristics {
        let lighting = await analyzeLightingConditions(image: image)
        let angle = await analyzeFaceAngle(image: image)
        let quality = await imageProcessor.assessImageQuality(image)
        let skinTone = try await analyzeSkinTone(image: image)
        
        return PhotoCharacteristics(
            lighting: lighting,
            faceAngle: angle,
            imageQuality: quality,
            skinTone: skinTone,
            isGroupPhoto: await detectGroupPhoto(image: image),
            isOutdoor: await detectOutdoorScene(image: image)
        )
    }
    
    private func analyzeEnhancementOpportunities(
        baseAnalysis: ImageAnalysisResult,
        beautyAnalysis: BeautyAnalysisResult,
        characteristics: PhotoCharacteristics
    ) async -> [EnhancementOpportunity] {
        
        var opportunities: [EnhancementOpportunity] = []
        
        // Lighting opportunities
        if characteristics.lighting.needsImprovement {
            opportunities.append(EnhancementOpportunity(
                type: .lighting,
                priority: .high,
                confidence: characteristics.lighting.confidence,
                recommendedIntensity: characteristics.lighting.recommendedCorrection,
                reason: "Improve lighting conditions"
            ))
        }
        
        // Skin enhancement opportunities
        if let face = baseAnalysis.primaryFace {
            if face.faceQuality.lighting < 0.7 {
                opportunities.append(EnhancementOpportunity(
                    type: .skinSmoothing,
                    priority: .medium,
                    confidence: 0.8,
                    recommendedIntensity: calculateSkinSmoothingIntensity(faceQuality: face.faceQuality),
                    reason: "Enhance skin appearance"
                ))
            }
            
            // Eye enhancement
            if face.faceAnalysis.eyeOpenness > 0.7 {
                opportunities.append(EnhancementOpportunity(
                    type: .eyeBrightening,
                    priority: .medium,
                    confidence: 0.9,
                    recommendedIntensity: 0.3,
                    reason: "Brighten and enhance eyes"
                ))
            }
        }
        
        // Overall enhancement opportunity
        if beautyAnalysis.enhancementPotential > 0.3 {
            opportunities.append(EnhancementOpportunity(
                type: .autoEnhance,
                priority: .high,
                confidence: beautyAnalysis.enhancementPotential,
                recommendedIntensity: min(beautyAnalysis.enhancementPotential, 0.8),
                reason: "General photo enhancement"
            ))
        }
        
        return opportunities.sorted { $0.priority.weight > $1.priority.weight }
    }
    
    // MARK: - Enhancement Strategy Generation
    
    private func generateEnhancementStrategy(
        analysis: ComprehensiveImageAnalysis,
        mode: EnhancementMode
    ) async -> EnhancementStrategy {
        
        guard let profile = enhancementProfiles[mode] else {
            return EnhancementStrategy.default(for: mode)
        }
        
        // Adapt profile to image characteristics
        let adaptedProfile = await adaptProfileToImage(profile, analysis: analysis)
        
        // Apply user learning
        let learnedProfile = await applyUserLearning(adaptedProfile, analysis: analysis)
        
        // Generate specific enhancements
        let enhancements = await generateSpecificEnhancements(
            profile: learnedProfile,
            opportunities: analysis.enhancementOpportunities
        )
        
        return EnhancementStrategy(
            mode: mode,
            enhancements: enhancements,
            confidenceScore: calculateStrategyConfidence(analysis: analysis, profile: learnedProfile),
            estimatedImprovements: calculateEstimatedImprovements(enhancements: enhancements),
            estimatedFullProcessingTime: calculateProcessingTime(enhancements: enhancements)
        )
    }
    
    private func generatePreviewStrategy(
        analysis: QuickImageAnalysis,
        mode: EnhancementMode
    ) async -> PreviewStrategy {
        
        guard let profile = enhancementProfiles[mode] else {
            return PreviewStrategy.default(for: mode)
        }
        
        // Quick adaptation for preview
        let quickEnhancements = profile.getQuickEnhancements(for: analysis)
        
        return PreviewStrategy(
            mode: mode,
            quickEnhancements: quickEnhancements,
            confidenceScore: 0.7, // Conservative for preview
            estimatedImprovements: profile.estimatedImprovements,
            estimatedFullProcessingTime: profile.averageProcessingTime
        )
    }
    
    // MARK: - Enhancement Application
    
    private func applyEnhancementsPipeline(
        image: UIImage,
        strategy: EnhancementStrategy,
        progressCallback: @escaping (Float) -> Void
    ) async throws -> UIImage {
        
        guard let ciImage = CIImage(image: image) else {
            throw AutoEnhancementError.invalidImage
        }
        
        var currentImage = ciImage
        let totalEnhancements = strategy.enhancements.count
        
        for (index, enhancement) in strategy.enhancements.enumerated() {
            let progress = Float(index) / Float(totalEnhancements)
            progressCallback(progress)
            
            currentImage = try await applyIndividualEnhancement(
                image: currentImage,
                enhancement: enhancement
            )
        }
        
        // Final processing and cleanup
        currentImage = await applyFinalOptimizations(image: currentImage)
        
        guard let cgImage = ciContext.createCGImage(currentImage, from: currentImage.extent) else {
            throw AutoEnhancementError.processingFailed("Failed to create final image")
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    private func applyPreviewEnhancements(
        image: UIImage,
        strategy: PreviewStrategy
    ) async throws -> UIImage {
        
        guard let ciImage = CIImage(image: image) else {
            throw AutoEnhancementError.invalidImage
        }
        
        var currentImage = ciImage
        
        // Apply quick enhancements for preview
        for enhancement in strategy.quickEnhancements {
            currentImage = try await applyQuickEnhancement(
                image: currentImage,
                enhancement: enhancement
            )
        }
        
        // Create preview-sized image for performance
        let previewSize = CGSize(width: 400, height: 400)
        currentImage = currentImage.resized(to: previewSize)
        
        guard let cgImage = ciContext.createCGImage(currentImage, from: currentImage.extent) else {
            throw AutoEnhancementError.processingFailed("Failed to create preview image")
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    private func applyIndividualEnhancement(
        image: CIImage,
        enhancement: Enhancement
    ) async throws -> CIImage {
        
        switch enhancement.type {
        case .autoEnhance:
            return try await applyAutoEnhancement(image: image, intensity: enhancement.intensity)
            
        case .skinSmoothing:
            return try await applySkinSmoothing(image: image, intensity: enhancement.intensity)
            
        case .eyeBrightening:
            return try await applyEyeBrightening(image: image, intensity: enhancement.intensity)
            
        case .teethWhitening:
            return try await applyTeethWhitening(image: image, intensity: enhancement.intensity)
            
        case .brightness, .contrast, .saturation:
            return try await applyBasicAdjustment(image: image, enhancement: enhancement)
            
        case .backgroundBlur:
            return try await applyPortraitMode(image: image, intensity: enhancement.intensity)
            
        default:
            return image // Fallback for unsupported enhancements
        }
    }
    
    // MARK: - Setup Methods
    
    private func setupEnhancementProfiles() {
        enhancementProfiles = [
            .natural: EnhancementProfile.natural,
            .glam: EnhancementProfile.glam,
            .hd: EnhancementProfile.hd,
            .studio: EnhancementProfile.studio
        ]
    }
    
    private func setupLearningSystem() {
        // Initialize learning system with any saved data
        learningData.loadUserPreferences()
    }
    
    // MARK: - Helper Methods
    
    private func calculateSkinSmoothingIntensity(faceQuality: DetailedFaceQuality) -> Float {
        // Dynamic intensity based on face quality
        let baseIntensity: Float = 0.3
        let qualityFactor = 1.0 - faceQuality.overallScore
        return min(baseIntensity + (qualityFactor * 0.4), 0.7)
    }
    
    private func detectSceneType(image: UIImage) async -> SceneType {
        // Quick scene detection for preview
        // This would use ML model in production
        return .portrait // Simplified for now
    }
    
    private func detectGroupPhoto(image: UIImage) async -> Bool {
        // Detect if image contains multiple people
        // This would use face detection count
        return false // Simplified for now
    }
    
    private func detectOutdoorScene(image: UIImage) async -> Bool {
        // Detect outdoor vs indoor scene
        // This would use scene classification model
        return false // Simplified for now
    }
    
    private func analyzeLightingConditions(image: UIImage) async -> LightingAnalysis {
        // Analyze lighting quality and conditions
        return LightingAnalysis(
            quality: 0.7,
            type: .natural,
            needsImprovement: false,
            confidence: 0.8,
            recommendedCorrection: 0.2
        )
    }
    
    private func analyzeFaceAngle(image: UIImage) async -> FaceAngleAnalysis {
        // Analyze face pose and angle
        return FaceAngleAnalysis(
            angle: 0.0,
            isOptimal: true,
            confidence: 0.8
        )
    }
    
    private func analyzeSkinTone(image: UIImage) async throws -> SkinToneAnalysis {
        // Analyze skin tone for color corrections
        return SkinToneAnalysis(
            dominantTone: .medium,
            undertone: .neutral,
            confidence: 0.8
        )
    }
}

// MARK: - Supporting Types

/// Comprehensive image analysis result
struct ComprehensiveImageAnalysis {
    let baseAnalysis: ImageAnalysisResult
    let beautyAnalysis: BeautyAnalysisResult
    let photoCharacteristics: PhotoCharacteristics
    let enhancementOpportunities: [EnhancementOpportunity]
}

/// Quick analysis for previews
struct QuickImageAnalysis {
    let hasFace: Bool
    let primaryFace: DetailedFaceDetectionResult?
    let imageQuality: Float
    let sceneType: SceneType
}

/// Photo characteristics analysis
struct PhotoCharacteristics {
    let lighting: LightingAnalysis
    let faceAngle: FaceAngleAnalysis
    let imageQuality: Float
    let skinTone: SkinToneAnalysis
    let isGroupPhoto: Bool
    let isOutdoor: Bool
}

/// Enhancement opportunity
struct EnhancementOpportunity {
    let type: EnhancementType
    let priority: EnhancementPriority
    let confidence: Float
    let recommendedIntensity: Float
    let reason: String
}

/// Enhancement priority levels
enum EnhancementPriority {
    case low, medium, high, critical
    
    var weight: Float {
        switch self {
        case .low: return 0.3
        case .medium: return 0.6
        case .high: return 0.8
        case .critical: return 1.0
        }
    }
}

/// Auto enhancement result
struct AutoEnhancementResult {
    let originalImage: UIImage
    let enhancedImage: UIImage
    let mode: EnhancementMode
    let appliedEnhancements: [Enhancement]
    let analysis: ComprehensiveImageAnalysis
    let effectiveness: EffectivenessAnalysis
    let processingTime: TimeInterval
    let confidence: Float
    
    var improvementScore: Float {
        effectiveness.overallImprovement
    }
    
    var isSignificantImprovement: Bool {
        improvementScore > 0.2
    }
}

/// Enhancement preview
struct EnhancementPreview {
    let previewImage: UIImage
    let mode: EnhancementMode
    let estimatedImprovements: [String: Float]
    let confidence: Float
    let estimatedProcessingTime: TimeInterval
}

/// Enhancement modes for one-tap enhancement
enum EnhancementMode: String, CaseIterable {
    case natural = "natural"
    case glam = "glam"
    case hd = "hd"
    case studio = "studio"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .natural: return "Natural"
        case .glam: return "Glam"
        case .hd: return "HD"
        case .studio: return "Studio"
        case .custom: return "Custom"
        }
    }
    
    var description: String {
        switch self {
        case .natural: return "Subtle improvements maintaining authenticity"
        case .glam: return "Enhanced beauty for special occasions"
        case .hd: return "High-definition clarity and detail"
        case .studio: return "Professional portrait quality"
        case .custom: return "Your personalized enhancement"
        }
    }
    
    var icon: String {
        switch self {
        case .natural: return "leaf.fill"
        case .glam: return "sparkles"
        case .hd: return "hd.circle.fill"
        case .studio: return "camera.aperture"
        case .custom: return "person.circle.fill"
        }
    }
}

// MARK: - Error Types

enum AutoEnhancementError: LocalizedError {
    case invalidImage
    case processingFailed(String)
    case analysisFailure(String)
    case modelNotAvailable
    case insufficientQuality
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format. Please use a valid image file."
        case .processingFailed(let details):
            return "Enhancement processing failed: \(details)"
        case .analysisFailure(let details):
            return "Image analysis failed: \(details)"
        case .modelNotAvailable:
            return "AI model is not available. Please try again later."
        case .insufficientQuality:
            return "Image quality is too low for enhancement. Please use a higher quality image."
        }
    }
}