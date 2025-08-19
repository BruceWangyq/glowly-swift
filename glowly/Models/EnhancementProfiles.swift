//
//  EnhancementProfiles.swift
//  Glowly
//
//  Enhancement profiles and modes for one-tap auto enhancement
//

import Foundation
import UIKit

/// Base enhancement profile structure
struct EnhancementProfile: Codable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let mode: EnhancementMode
    let enhancements: [EnhancementConfiguration]
    let intensityMultiplier: Float
    let applicabilityConditions: [ApplicabilityCondition]
    let estimatedImprovements: [String: Float]
    let averageProcessingTime: TimeInterval
    let targetAudience: TargetAudience
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        mode: EnhancementMode,
        enhancements: [EnhancementConfiguration],
        intensityMultiplier: Float = 1.0,
        applicabilityConditions: [ApplicabilityCondition] = [],
        estimatedImprovements: [String: Float] = [:],
        averageProcessingTime: TimeInterval = 2.0,
        targetAudience: TargetAudience = .general
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.mode = mode
        self.enhancements = enhancements
        self.intensityMultiplier = intensityMultiplier
        self.applicabilityConditions = applicabilityConditions
        self.estimatedImprovements = estimatedImprovements
        self.averageProcessingTime = averageProcessingTime
        self.targetAudience = targetAudience
    }
    
    /// Get quick enhancements for preview
    func getQuickEnhancements(for analysis: QuickImageAnalysis) -> [EnhancementConfiguration] {
        return enhancements.filter { $0.isQuickProcessing }
    }
    
    /// Check if profile is applicable to the given analysis
    func isApplicable(to analysis: ComprehensiveImageAnalysis) -> Bool {
        return applicabilityConditions.allSatisfy { condition in
            condition.isMet(by: analysis)
        }
    }
    
    /// Calculate adapted intensity based on image characteristics
    func getAdaptedIntensity(for enhancement: EnhancementType, analysis: ComprehensiveImageAnalysis) -> Float {
        guard let config = enhancements.first(where: { $0.type == enhancement }) else {
            return 0.5
        }
        
        var intensity = config.baseIntensity * intensityMultiplier
        
        // Apply adaptive adjustments
        for adjustment in config.adaptiveAdjustments {
            intensity *= adjustment.calculateMultiplier(for: analysis)
        }
        
        return max(0.0, min(1.0, intensity))
    }
}

/// Individual enhancement configuration
struct EnhancementConfiguration: Codable, Hashable {
    let type: EnhancementType
    let baseIntensity: Float
    let priority: Int
    let parameters: [String: Float]
    let adaptiveAdjustments: [AdaptiveAdjustment]
    let isQuickProcessing: Bool
    let processingOrder: Int
    let prerequisites: [EnhancementType]
    let conflictsWith: [EnhancementType]
    
    init(
        type: EnhancementType,
        baseIntensity: Float,
        priority: Int = 50,
        parameters: [String: Float] = [:],
        adaptiveAdjustments: [AdaptiveAdjustment] = [],
        isQuickProcessing: Bool = false,
        processingOrder: Int = 0,
        prerequisites: [EnhancementType] = [],
        conflictsWith: [EnhancementType] = []
    ) {
        self.type = type
        self.baseIntensity = baseIntensity
        self.priority = priority
        self.parameters = parameters
        self.adaptiveAdjustments = adaptiveAdjustments
        self.isQuickProcessing = isQuickProcessing
        self.processingOrder = processingOrder
        self.prerequisites = prerequisites
        self.conflictsWith = conflictsWith
    }
}

/// Adaptive adjustment for dynamic intensity calculation
struct AdaptiveAdjustment: Codable, Hashable {
    let factor: AdaptiveFactor
    let multiplier: Float
    let threshold: Float?
    let condition: ComparisonOperator
    
    func calculateMultiplier(for analysis: ComprehensiveImageAnalysis) -> Float {
        let value = extractValue(from: analysis)
        
        if let threshold = threshold {
            let conditionMet = condition.evaluate(value, threshold)
            return conditionMet ? multiplier : 1.0
        }
        
        // Linear scaling if no threshold
        return 1.0 + (value * (multiplier - 1.0))
    }
    
    private func extractValue(from analysis: ComprehensiveImageAnalysis) -> Float {
        switch factor {
        case .imageQuality:
            return analysis.photoCharacteristics.imageQuality
        case .lightingQuality:
            return analysis.photoCharacteristics.lighting.quality
        case .faceQuality:
            return analysis.baseAnalysis.primaryFace?.faceQuality.overallScore ?? 0.5
        case .skinQuality:
            return analysis.baseAnalysis.primaryFace?.skinToneAnalysis.confidence ?? 0.5
        case .beautyScore:
            return analysis.beautyAnalysis.overallScore
        case .age:
            return analysis.baseAnalysis.primaryFace?.faceAnalysis.age.normalizedValue ?? 0.5
        }
    }
}

/// Factors for adaptive adjustments
enum AdaptiveFactor: String, Codable, CaseIterable {
    case imageQuality = "image_quality"
    case lightingQuality = "lighting_quality"
    case faceQuality = "face_quality"
    case skinQuality = "skin_quality"
    case beautyScore = "beauty_score"
    case age = "age"
}

/// Applicability conditions for profiles
struct ApplicabilityCondition: Codable, Hashable {
    let factor: AdaptiveFactor
    let threshold: Float
    let condition: ComparisonOperator
    
    func isMet(by analysis: ComprehensiveImageAnalysis) -> Bool {
        let value = extractValue(from: analysis)
        return condition.evaluate(value, threshold)
    }
    
    private func extractValue(from analysis: ComprehensiveImageAnalysis) -> Float {
        switch factor {
        case .imageQuality:
            return analysis.photoCharacteristics.imageQuality
        case .lightingQuality:
            return analysis.photoCharacteristics.lighting.quality
        case .faceQuality:
            return analysis.baseAnalysis.primaryFace?.faceQuality.overallScore ?? 0.0
        case .skinQuality:
            return analysis.baseAnalysis.primaryFace?.skinToneAnalysis.confidence ?? 0.0
        case .beautyScore:
            return analysis.beautyAnalysis.overallScore
        case .age:
            return analysis.baseAnalysis.primaryFace?.faceAnalysis.age.normalizedValue ?? 0.5
        }
    }
}

/// Target audience for enhancement profiles
enum TargetAudience: String, Codable, CaseIterable {
    case general = "general"
    case professional = "professional"
    case social = "social"
    case artistic = "artistic"
    case commercial = "commercial"
    
    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Predefined Enhancement Profiles

extension EnhancementProfile {
    
    /// Natural enhancement profile - subtle improvements
    static let natural = EnhancementProfile(
        name: "Natural",
        description: "Subtle improvements maintaining authenticity",
        mode: .natural,
        enhancements: [
            EnhancementConfiguration(
                type: .autoEnhance,
                baseIntensity: 0.3,
                priority: 100,
                adaptiveAdjustments: [
                    AdaptiveAdjustment(factor: .imageQuality, multiplier: 1.2, threshold: 0.6, condition: .lessThan)
                ],
                isQuickProcessing: true,
                processingOrder: 1
            ),
            EnhancementConfiguration(
                type: .skinSmoothing,
                baseIntensity: 0.2,
                priority: 80,
                adaptiveAdjustments: [
                    AdaptiveAdjustment(factor: .age, multiplier: 1.5, threshold: 0.6, condition: .greaterThan),
                    AdaptiveAdjustment(factor: .imageQuality, multiplier: 0.8, threshold: 0.5, condition: .lessThan)
                ],
                isQuickProcessing: false,
                processingOrder: 3
            ),
            EnhancementConfiguration(
                type: .eyeBrightening,
                baseIntensity: 0.25,
                priority: 70,
                isQuickProcessing: true,
                processingOrder: 4
            ),
            EnhancementConfiguration(
                type: .brightness,
                baseIntensity: 0.15,
                priority: 90,
                adaptiveAdjustments: [
                    AdaptiveAdjustment(factor: .lightingQuality, multiplier: 2.0, threshold: 0.5, condition: .lessThan)
                ],
                isQuickProcessing: true,
                processingOrder: 2
            )
        ],
        intensityMultiplier: 0.8,
        estimatedImprovements: [
            "overall_quality": 0.15,
            "skin_appearance": 0.12,
            "eye_brightness": 0.10,
            "lighting": 0.08
        ],
        averageProcessingTime: 1.5,
        targetAudience: .general
    )
    
    /// Glam enhancement profile - enhanced beauty for special occasions
    static let glam = EnhancementProfile(
        name: "Glam",
        description: "Enhanced beauty for special occasions",
        mode: .glam,
        enhancements: [
            EnhancementConfiguration(
                type: .autoEnhance,
                baseIntensity: 0.6,
                priority: 100,
                isQuickProcessing: true,
                processingOrder: 1
            ),
            EnhancementConfiguration(
                type: .skinSmoothing,
                baseIntensity: 0.4,
                priority: 95,
                adaptiveAdjustments: [
                    AdaptiveAdjustment(factor: .age, multiplier: 1.3, threshold: 0.5, condition: .greaterThan)
                ],
                processingOrder: 3
            ),
            EnhancementConfiguration(
                type: .eyeBrightening,
                baseIntensity: 0.5,
                priority: 90,
                isQuickProcessing: true,
                processingOrder: 4
            ),
            EnhancementConfiguration(
                type: .teethWhitening,
                baseIntensity: 0.3,
                priority: 75,
                processingOrder: 5
            ),
            EnhancementConfiguration(
                type: .lipEnhancement,
                baseIntensity: 0.25,
                priority: 70,
                processingOrder: 6
            ),
            EnhancementConfiguration(
                type: .contrast,
                baseIntensity: 0.2,
                priority: 85,
                isQuickProcessing: true,
                processingOrder: 2
            ),
            EnhancementConfiguration(
                type: .saturation,
                baseIntensity: 0.15,
                priority: 80,
                isQuickProcessing: true,
                processingOrder: 2
            )
        ],
        intensityMultiplier: 1.2,
        estimatedImprovements: [
            "overall_quality": 0.25,
            "skin_appearance": 0.20,
            "eye_brightness": 0.18,
            "teeth_whiteness": 0.15,
            "lip_enhancement": 0.12,
            "color_vibrancy": 0.10
        ],
        averageProcessingTime: 3.0,
        targetAudience: .social
    )
    
    /// HD enhancement profile - high-definition clarity and detail
    static let hd = EnhancementProfile(
        name: "HD",
        description: "High-definition clarity and detail enhancement",
        mode: .hd,
        enhancements: [
            EnhancementConfiguration(
                type: .clarity,
                baseIntensity: 0.6,
                priority: 100,
                adaptiveAdjustments: [
                    AdaptiveAdjustment(factor: .imageQuality, multiplier: 1.5, threshold: 0.7, condition: .greaterThan)
                ],
                isQuickProcessing: true,
                processingOrder: 1
            ),
            EnhancementConfiguration(
                type: .autoEnhance,
                baseIntensity: 0.4,
                priority: 95,
                isQuickProcessing: true,
                processingOrder: 2
            ),
            EnhancementConfiguration(
                type: .skinSmoothing,
                baseIntensity: 0.3,
                priority: 85,
                adaptiveAdjustments: [
                    AdaptiveAdjustment(factor: .imageQuality, multiplier: 0.7, threshold: 0.8, condition: .greaterThan)
                ],
                processingOrder: 4
            ),
            EnhancementConfiguration(
                type: .eyeBrightening,
                baseIntensity: 0.4,
                priority: 80,
                isQuickProcessing: true,
                processingOrder: 5
            ),
            EnhancementConfiguration(
                type: .contrast,
                baseIntensity: 0.25,
                priority: 90,
                isQuickProcessing: true,
                processingOrder: 3
            )
        ],
        intensityMultiplier: 1.0,
        applicabilityConditions: [
            ApplicabilityCondition(factor: .imageQuality, threshold: 0.5, condition: .greaterThan)
        ],
        estimatedImprovements: [
            "clarity": 0.30,
            "detail": 0.25,
            "sharpness": 0.22,
            "overall_quality": 0.20,
            "skin_texture": 0.15
        ],
        averageProcessingTime: 2.5,
        targetAudience: .professional
    )
    
    /// Studio enhancement profile - professional portrait quality
    static let studio = EnhancementProfile(
        name: "Studio",
        description: "Professional portrait-quality enhancements",
        mode: .studio,
        enhancements: [
            EnhancementConfiguration(
                type: .autoEnhance,
                baseIntensity: 0.5,
                priority: 100,
                isQuickProcessing: true,
                processingOrder: 1
            ),
            EnhancementConfiguration(
                type: .backgroundBlur,
                baseIntensity: 0.6,
                priority: 95,
                prerequisites: [.autoEnhance],
                processingOrder: 7
            ),
            EnhancementConfiguration(
                type: .skinSmoothing,
                baseIntensity: 0.35,
                priority: 90,
                adaptiveAdjustments: [
                    AdaptiveAdjustment(factor: .age, multiplier: 1.4, threshold: 0.6, condition: .greaterThan),
                    AdaptiveAdjustment(factor: .faceQuality, multiplier: 1.2, threshold: 0.7, condition: .greaterThan)
                ],
                processingOrder: 3
            ),
            EnhancementConfiguration(
                type: .eyeBrightening,
                baseIntensity: 0.4,
                priority: 85,
                isQuickProcessing: true,
                processingOrder: 4
            ),
            EnhancementConfiguration(
                type: .teethWhitening,
                baseIntensity: 0.25,
                priority: 80,
                processingOrder: 5
            ),
            EnhancementConfiguration(
                type: .brightness,
                baseIntensity: 0.2,
                priority: 88,
                adaptiveAdjustments: [
                    AdaptiveAdjustment(factor: .lightingQuality, multiplier: 2.5, threshold: 0.6, condition: .lessThan)
                ],
                isQuickProcessing: true,
                processingOrder: 2
            ),
            EnhancementConfiguration(
                type: .contrast,
                baseIntensity: 0.15,
                priority: 75,
                isQuickProcessing: true,
                processingOrder: 6
            )
        ],
        intensityMultiplier: 1.1,
        applicabilityConditions: [
            ApplicabilityCondition(factor: .faceQuality, threshold: 0.4, condition: .greaterThan)
        ],
        estimatedImprovements: [
            "professional_quality": 0.35,
            "background_separation": 0.30,
            "skin_appearance": 0.22,
            "lighting": 0.20,
            "overall_composition": 0.18
        ],
        averageProcessingTime: 4.0,
        targetAudience: .professional
    )
}

/// Custom enhancement profile for user-trained personalization
struct CustomEnhancementProfile: Codable {
    let id: UUID
    let userId: UUID
    let name: String
    let createdAt: Date
    let lastUpdated: Date
    var enhancements: [Enhancement]
    var confidence: Float
    var usageCount: Int
    var averageRating: Float
    var learningData: CustomProfileLearningData
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        name: String = "My Custom Style",
        createdAt: Date = Date(),
        lastUpdated: Date = Date(),
        enhancements: [Enhancement] = [],
        confidence: Float = 0.5,
        usageCount: Int = 0,
        averageRating: Float = 0.0,
        learningData: CustomProfileLearningData = CustomProfileLearningData()
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.createdAt = createdAt
        self.lastUpdated = lastUpdated
        self.enhancements = enhancements
        self.confidence = confidence
        self.usageCount = usageCount
        self.averageRating = averageRating
        self.learningData = learningData
    }
    
    mutating func updateFromFeedback(_ feedback: UserEnhancementFeedback) {
        // Update average rating
        let totalRating = averageRating * Float(usageCount) + feedback.overallRating
        usageCount += 1
        averageRating = totalRating / Float(usageCount)
        
        // Update confidence based on feedback
        let feedbackScore = (feedback.satisfaction + feedback.naturalness) / 2.0
        confidence = (confidence * 0.8) + (feedbackScore * 0.2)
        
        // Update learning data
        learningData.processFeedback(feedback)
        
        lastUpdated = Date()
    }
    
    func getAdaptedProfile(for analysis: ComprehensiveImageAnalysis) -> CustomEnhancementProfile {
        var adapted = self
        
        // Apply learned adaptations
        adapted.enhancements = learningData.adaptEnhancements(enhancements, for: analysis)
        
        return adapted
    }
}

/// Learning data for custom profiles
struct CustomProfileLearningData: Codable {
    var preferredIntensities: [EnhancementType: Float] = [:]
    var contextualAdjustments: [String: Float] = [:]
    var successfulCombinations: [[EnhancementType]] = []
    var feedbackHistory: [UserEnhancementFeedback] = []
    
    mutating func processFeedback(_ feedback: UserEnhancementFeedback) {
        feedbackHistory.append(feedback)
        
        // Update preferred intensities based on feedback
        for enhancement in feedback.enhancementDetails {
            let currentPreference = preferredIntensities[enhancement.type] ?? 0.5
            let adjustment = (feedback.satisfaction - 0.5) * 0.1
            preferredIntensities[enhancement.type] = max(0.1, min(0.9, currentPreference + adjustment))
        }
        
        // Limit history size
        if feedbackHistory.count > 50 {
            feedbackHistory.removeFirst()
        }
    }
    
    func adaptEnhancements(_ enhancements: [Enhancement], for analysis: ComprehensiveImageAnalysis) -> [Enhancement] {
        return enhancements.map { enhancement in
            var adapted = enhancement
            
            // Apply learned intensity preferences
            if let preferredIntensity = preferredIntensities[enhancement.type] {
                adapted.intensity = (enhancement.intensity + preferredIntensity) / 2.0
            }
            
            return adapted
        }
    }
}

/// User feedback for enhancement learning
struct UserEnhancementFeedback: Codable {
    let id: UUID
    let userId: UUID
    let enhancementResultId: UUID
    let satisfaction: Float // 0.0 to 1.0
    let naturalness: Float // 0.0 to 1.0
    let overallRating: Float // 0.0 to 1.0
    let wouldUseAgain: Bool
    let enhancementDetails: [Enhancement]
    let comments: String?
    let timestamp: Date
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        enhancementResultId: UUID,
        satisfaction: Float,
        naturalness: Float,
        overallRating: Float,
        wouldUseAgain: Bool,
        enhancementDetails: [Enhancement],
        comments: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.enhancementResultId = enhancementResultId
        self.satisfaction = satisfaction
        self.naturalness = naturalness
        self.overallRating = overallRating
        self.wouldUseAgain = wouldUseAgain
        self.enhancementDetails = enhancementDetails
        self.comments = comments
        self.timestamp = timestamp
    }
}

// MARK: - Supporting Extensions

extension AgeCategory {
    var normalizedValue: Float {
        switch self {
        case .child: return 0.1
        case .teenager: return 0.3
        case .youngAdult: return 0.5
        case .adult: return 0.7
        case .senior: return 0.9
        }
    }
}