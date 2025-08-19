//
//  EnhancementSupportingModels.swift
//  Glowly
//
//  Supporting models and types for the auto enhancement system
//

import Foundation
import UIKit
import CoreImage

// MARK: - Enhancement Strategy and Processing

/// Enhancement strategy for processing pipeline
struct EnhancementStrategy {
    let mode: EnhancementMode
    let enhancements: [Enhancement]
    let confidenceScore: Float
    let estimatedImprovements: [String: Float]
    let estimatedFullProcessingTime: TimeInterval
    
    init(
        mode: EnhancementMode,
        enhancements: [Enhancement],
        confidenceScore: Float,
        estimatedImprovements: [String: Float] = [:],
        estimatedFullProcessingTime: TimeInterval = 2.0
    ) {
        self.mode = mode
        self.enhancements = enhancements
        self.confidenceScore = confidenceScore
        self.estimatedImprovements = estimatedImprovements
        self.estimatedFullProcessingTime = estimatedFullProcessingTime
    }
    
    init(from profile: CustomEnhancementProfile) {
        self.mode = .custom
        self.enhancements = profile.enhancements
        self.confidenceScore = profile.confidence
        self.estimatedImprovements = [:]
        self.estimatedFullProcessingTime = 3.0
    }
    
    static func `default`(for mode: EnhancementMode) -> EnhancementStrategy {
        return EnhancementStrategy(
            mode: mode,
            enhancements: [
                Enhancement(type: .autoEnhance, intensity: 0.5)
            ],
            confidenceScore: 0.7
        )
    }
}

/// Preview strategy for quick enhancement previews
struct PreviewStrategy {
    let mode: EnhancementMode
    let quickEnhancements: [EnhancementConfiguration]
    let confidenceScore: Float
    let estimatedImprovements: [String: Float]
    let estimatedFullProcessingTime: TimeInterval
    
    static func `default`(for mode: EnhancementMode) -> PreviewStrategy {
        return PreviewStrategy(
            mode: mode,
            quickEnhancements: [
                EnhancementConfiguration(type: .autoEnhance, baseIntensity: 0.3, isQuickProcessing: true)
            ],
            confidenceScore: 0.6,
            estimatedImprovements: ["overall": 0.2],
            estimatedFullProcessingTime: 1.5
        )
    }
}

// MARK: - Analysis Supporting Types

/// Lighting analysis result
struct LightingAnalysis {
    let quality: Float
    let type: LightingType
    let needsImprovement: Bool
    let confidence: Float
    let recommendedCorrection: Float
}

/// Lighting types
enum LightingType: String, CaseIterable {
    case natural = "natural"
    case artificial = "artificial"
    case mixed = "mixed"
    case backlit = "backlit"
    case lowLight = "low_light"
    
    var displayName: String {
        switch self {
        case .natural: return "Natural"
        case .artificial: return "Artificial"
        case .mixed: return "Mixed"
        case .backlit: return "Backlit"
        case .lowLight: return "Low Light"
        }
    }
}

/// Face angle analysis
struct FaceAngleAnalysis {
    let angle: Float
    let isOptimal: Bool
    let confidence: Float
}

/// Skin tone analysis
struct SkinToneAnalysis {
    let dominantTone: SkinTone
    let undertone: SkinUndertone
    let confidence: Float
}

/// Skin tone categories
enum SkinTone: String, CaseIterable {
    case veryLight = "very_light"
    case light = "light"
    case medium = "medium"
    case dark = "dark"
    case veryDark = "very_dark"
    
    var displayName: String {
        switch self {
        case .veryLight: return "Very Light"
        case .light: return "Light"
        case .medium: return "Medium"
        case .dark: return "Dark"
        case .veryDark: return "Very Dark"
        }
    }
}

/// Skin undertones
enum SkinUndertone: String, CaseIterable {
    case cool = "cool"
    case warm = "warm"
    case neutral = "neutral"
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var enhancementAdjustments: [String: Float] {
        switch self {
        case .cool:
            return ["blue_boost": 0.1, "yellow_reduce": -0.1]
        case .warm:
            return ["yellow_boost": 0.1, "blue_reduce": -0.1]
        case .neutral:
            return [:]
        }
    }
}

/// Scene type classification
enum SceneType: String, CaseIterable {
    case portrait = "portrait"
    case selfie = "selfie"
    case group = "group"
    case outdoor = "outdoor"
    case indoor = "indoor"
    case professional = "professional"
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var recommendedEnhancements: [EnhancementType] {
        switch self {
        case .portrait, .selfie:
            return [.skinSmoothing, .eyeBrightening, .autoEnhance]
        case .group:
            return [.autoEnhance, .brightness, .contrast]
        case .outdoor:
            return [.autoEnhance, .saturation, .clarity]
        case .indoor:
            return [.brightness, .warmth, .autoEnhance]
        case .professional:
            return [.skinSmoothing, .eyeBrightening, .backgroundBlur, .clarity]
        }
    }
}

// MARK: - Image Quality Assessment

/// Image quality result with detailed metrics
struct ImageQualityResult {
    let overallScore: Float
    let sharpness: Float
    let noise: Float
    let exposure: Float
    let contrast: Float
    let colorBalance: Float
    
    var improvementAreas: [QualityImprovementArea] {
        var areas: [QualityImprovementArea] = []
        
        if sharpness < 0.6 { areas.append(.sharpness) }
        if noise > 0.4 { areas.append(.noise) }
        if exposure < 0.5 || exposure > 0.8 { areas.append(.exposure) }
        if contrast < 0.6 { areas.append(.contrast) }
        if colorBalance < 0.6 { areas.append(.colorBalance) }
        
        return areas
    }
}

/// Quality improvement areas
enum QualityImprovementArea: String, CaseIterable {
    case sharpness = "sharpness"
    case noise = "noise"
    case exposure = "exposure"
    case contrast = "contrast"
    case colorBalance = "color_balance"
    case lighting = "lighting"
    case pose = "pose"
    case expression = "expression"
    case occlusion = "occlusion"
    case resolution = "resolution"
    
    var improvementSuggestion: String {
        switch self {
        case .sharpness:
            return "Enhance image sharpness and clarity"
        case .noise:
            return "Reduce image noise and grain"
        case .exposure:
            return "Adjust exposure for better brightness"
        case .contrast:
            return "Improve image contrast"
        case .colorBalance:
            return "Correct color balance and temperature"
        case .lighting:
            return "Enhance lighting conditions"
        case .pose:
            return "Optimize face pose and angle"
        case .expression:
            return "Enhance facial expression"
        case .occlusion:
            return "Address facial occlusions"
        case .resolution:
            return "Improve image resolution"
        }
    }
}

// MARK: - Enhanced Analysis Results

/// Beauty analysis result with comprehensive metrics
struct BeautyAnalysisResult {
    let overallScore: Float
    let symmetryScore: Float
    let proportionScore: Float
    let featureQualityScore: Float
    let skinQualityScore: Float
    let enhancementPotential: Float
    
    var isHighQuality: Bool {
        overallScore > 0.7
    }
    
    var primaryImprovementAreas: [BeautyImprovementArea] {
        var areas: [BeautyImprovementArea] = []
        
        if symmetryScore < 0.6 { areas.append(.faceSymmetry) }
        if proportionScore < 0.6 { areas.append(.faceProportions) }
        if featureQualityScore < 0.6 { areas.append(.featureQuality) }
        if skinQualityScore < 0.6 { areas.append(.skinQuality) }
        
        return areas
    }
}

/// Beauty improvement areas
enum BeautyImprovementArea: String, CaseIterable {
    case faceSymmetry = "face_symmetry"
    case faceProportions = "face_proportions"
    case featureQuality = "feature_quality"
    case skinQuality = "skin_quality"
    case eyeBrightness = "eye_brightness"
    case skinTone = "skin_tone"
    
    var enhancementRecommendations: [EnhancementType] {
        switch self {
        case .faceSymmetry:
            return [.faceSlimming, .autoEnhance]
        case .faceProportions:
            return [.eyeEnlargement, .faceSlimming]
        case .featureQuality:
            return [.eyeBrightening, .lipEnhancement]
        case .skinQuality:
            return [.skinSmoothing, .blemishRemoval]
        case .eyeBrightness:
            return [.eyeBrightening]
        case .skinTone:
            return [.skinTone, .warmth]
        }
    }
}

// MARK: - Age Category Extension

extension AgeCategory {
    var recommendedEnhancements: [EnhancementType] {
        switch self {
        case .child:
            return [.autoEnhance, .brightness]
        case .teenager:
            return [.skinSmoothing, .eyeBrightening, .autoEnhance]
        case .youngAdult:
            return [.skinSmoothing, .eyeBrightening, .teethWhitening, .autoEnhance]
        case .adult:
            return [.skinSmoothing, .eyeBrightening, .teethWhitening, .ageReduction, .autoEnhance]
        case .senior:
            return [.skinSmoothing, .ageReduction, .eyeBrightening, .autoEnhance]
        }
    }
}

// MARK: - Lighting Conditions Extension

extension LightingConditions {
    var correctionSuggestions: [EnhancementType] {
        switch self {
        case .excellent, .good:
            return []
        case .fair:
            return [.brightness, .contrast]
        case .poor:
            return [.brightness, .exposure, .shadows]
        case .lowLight:
            return [.brightness, .exposure, .shadows, .clarity]
        case .backlit:
            return [.shadows, .highlights, .exposure]
        case .harsh:
            return [.highlights, .contrast]
        case .mixed:
            return [.autoEnhance, .exposure]
        }
    }
}

// MARK: - Scene Type Extension

extension SceneType {
    static func detect(from analysis: ImageAnalysisResult) -> SceneType {
        // Simplified scene detection logic
        // In production, this would use ML models
        
        if analysis.faceCount == 1 {
            return .portrait
        } else if analysis.faceCount > 1 {
            return .group
        } else {
            return .outdoor // Default fallback
        }
    }
}

// MARK: - Error Types

/// Comprehensive error types for enhancement system
enum EnhancementSystemError: LocalizedError {
    case imageAnalysisFailed(String)
    case enhancementProcessingFailed(String)
    case insufficientImageQuality
    case unsupportedImageFormat
    case memoryLimitExceeded
    case processingTimeout
    case modelNotAvailable(String)
    case userProfileNotFound
    
    var errorDescription: String? {
        switch self {
        case .imageAnalysisFailed(let details):
            return "Image analysis failed: \(details)"
        case .enhancementProcessingFailed(let details):
            return "Enhancement processing failed: \(details)"
        case .insufficientImageQuality:
            return "Image quality is too low for enhancement"
        case .unsupportedImageFormat:
            return "Unsupported image format"
        case .memoryLimitExceeded:
            return "Memory limit exceeded during processing"
        case .processingTimeout:
            return "Processing timeout - operation took too long"
        case .modelNotAvailable(let modelName):
            return "AI model '\(modelName)' is not available"
        case .userProfileNotFound:
            return "User profile not found"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .imageAnalysisFailed, .enhancementProcessingFailed:
            return "Please try again with a different image"
        case .insufficientImageQuality:
            return "Please use a higher quality image"
        case .unsupportedImageFormat:
            return "Please use a JPEG or PNG image"
        case .memoryLimitExceeded:
            return "Please close other apps and try again"
        case .processingTimeout:
            return "Please try again or use a smaller image"
        case .modelNotAvailable:
            return "Please check your internet connection and try again"
        case .userProfileNotFound:
            return "Please complete your profile setup"
        }
    }
}

// MARK: - Performance and Resource Management

/// Resource usage monitoring
struct ResourceUsage {
    let memoryUsage: Int64
    let cpuUsage: Float
    let batteryLevel: Float
    let thermalState: ThermalState
    let timestamp: Date = Date()
    
    var isOptimalForProcessing: Bool {
        return memoryUsage < 500_000_000 && // 500MB
               cpuUsage < 70.0 &&
               batteryLevel > 0.2 &&
               thermalState != .critical
    }
}

/// Thermal state monitoring
enum ThermalState: String, CaseIterable {
    case nominal = "nominal"
    case fair = "fair"
    case serious = "serious"
    case critical = "critical"
    
    var processingAllowed: Bool {
        switch self {
        case .nominal, .fair:
            return true
        case .serious:
            return true // Reduced quality
        case .critical:
            return false
        }
    }
}

// MARK: - Processing Optimization

/// Processing optimization settings
struct ProcessingOptimization {
    let qualityLevel: QualityLevel
    let maxProcessingTime: TimeInterval
    let memoryLimit: Int64
    let thermalAware: Bool
    let batteryAware: Bool
    
    static let `default` = ProcessingOptimization(
        qualityLevel: .standard,
        maxProcessingTime: 30.0,
        memoryLimit: 500_000_000,
        thermalAware: true,
        batteryAware: true
    )
    
    static let performance = ProcessingOptimization(
        qualityLevel: .high,
        maxProcessingTime: 60.0,
        memoryLimit: 800_000_000,
        thermalAware: false,
        batteryAware: false
    )
    
    static let efficiency = ProcessingOptimization(
        qualityLevel: .standard,
        maxProcessingTime: 15.0,
        memoryLimit: 300_000_000,
        thermalAware: true,
        batteryAware: true
    )
}

// MARK: - User Preferences Integration

/// Enhancement preferences
struct EnhancementPreferences {
    let defaultMode: EnhancementMode
    let defaultIntensity: Float
    let autoSave: Bool
    let highQualityProcessing: Bool
    let preserveOriginal: Bool
    let enableAnalytics: Bool
    
    static let `default` = EnhancementPreferences(
        defaultMode: .natural,
        defaultIntensity: 0.8,
        autoSave: false,
        highQualityProcessing: true,
        preserveOriginal: true,
        enableAnalytics: true
    )
}

// MARK: - Accessibility Support

/// Accessibility features for enhancement interface
struct AccessibilityFeatures {
    let voiceOverEnabled: Bool
    let reduceMotion: Bool
    let highContrast: Bool
    let largeText: Bool
    
    var adaptedAnimationDuration: TimeInterval {
        return reduceMotion ? 0.1 : 0.3
    }
    
    var adaptedSpringDamping: Double {
        return reduceMotion ? 1.0 : 0.8
    }
}

// MARK: - Internationalization Support

/// Localization keys for enhancement features
enum EnhancementLocalizationKey: String, CaseIterable {
    case naturalMode = "enhancement.mode.natural"
    case glamMode = "enhancement.mode.glam"
    case hdMode = "enhancement.mode.hd"
    case studioMode = "enhancement.mode.studio"
    case customMode = "enhancement.mode.custom"
    
    case processing = "enhancement.processing"
    case complete = "enhancement.complete"
    case failed = "enhancement.failed"
    
    case beforeAfter = "enhancement.before_after"
    case intensity = "enhancement.intensity"
    case reset = "enhancement.reset"
    case save = "enhancement.save"
    case cancel = "enhancement.cancel"
    
    var localizedString: String {
        return NSLocalizedString(rawValue, comment: "")
    }
}