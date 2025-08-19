//
//  BeautyEnhancementModels.swift
//  Glowly
//
//  Data models for beauty enhancement recommendations and analysis
//

import Foundation
import UIKit

// MARK: - Beauty Recommendation Results

/// Comprehensive beauty recommendation result
struct BeautyRecommendationResult: Codable, Hashable {
    let imageAnalysis: ImageAnalysisResult
    let beautyAnalysis: BeautyAnalysisResult
    let recommendations: [PersonalizedRecommendation]
    let confidenceScore: Float
    let processingTime: TimeInterval
    let timestamp: Date
    
    var topRecommendations: [PersonalizedRecommendation] {
        Array(recommendations.prefix(5))
    }
    
    var highConfidenceRecommendations: [PersonalizedRecommendation] {
        recommendations.filter { $0.confidence > 0.8 }
    }
    
    var hasHighQualityAnalysis: Bool {
        confidenceScore > 0.7 && imageAnalysis.overallQualityScore > 0.6
    }
}

/// Personalized enhancement recommendation
struct PersonalizedRecommendation: Codable, Hashable {
    let id: UUID
    let enhancementType: EnhancementType
    let confidence: Float
    var recommendedIntensity: Float
    let reasoning: String
    let category: EnhancementCategory
    let priority: RecommendationPriority
    let estimatedImpact: ImpactLevel?
    let prerequisites: [EnhancementType]?
    let alternatives: [EnhancementType]?
    
    init(
        id: UUID = UUID(),
        enhancementType: EnhancementType,
        confidence: Float,
        recommendedIntensity: Float,
        reasoning: String,
        category: EnhancementCategory,
        priority: RecommendationPriority,
        estimatedImpact: ImpactLevel? = nil,
        prerequisites: [EnhancementType]? = nil,
        alternatives: [EnhancementType]? = nil
    ) {
        self.id = id
        self.enhancementType = enhancementType
        self.confidence = confidence
        self.recommendedIntensity = recommendedIntensity
        self.reasoning = reasoning
        self.category = category
        self.priority = priority
        self.estimatedImpact = estimatedImpact
        self.prerequisites = prerequisites
        self.alternatives = alternatives
    }
    
    var isHighPriority: Bool {
        priority == .high && confidence > 0.8
    }
    
    var effectivenessScore: Float {
        confidence * recommendedIntensity * priority.weight
    }
}

/// Priority levels for recommendations
enum RecommendationPriority: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var weight: Float {
        switch self {
        case .low: return 0.5
        case .medium: return 0.7
        case .high: return 0.9
        case .critical: return 1.0
        }
    }
    
    var color: UIColor {
        switch self {
        case .low: return .systemGray
        case .medium: return .systemBlue
        case .high: return .systemOrange
        case .critical: return .systemRed
        }
    }
}

/// Impact level of enhancements
enum ImpactLevel: String, Codable, CaseIterable {
    case subtle = "subtle"
    case moderate = "moderate"
    case dramatic = "dramatic"
    case transformative = "transformative"
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var intensityRange: ClosedRange<Float> {
        switch self {
        case .subtle: return 0.1...0.3
        case .moderate: return 0.3...0.6
        case .dramatic: return 0.6...0.8
        case .transformative: return 0.8...1.0
        }
    }
}

// MARK: - Enhancement Effectiveness

/// Analysis of enhancement effectiveness
struct EffectivenessAnalysis: Codable, Hashable {
    let overallImprovement: Float
    let qualityImprovement: Float
    let beautyScoreImprovement: Float
    let enhancementEffectiveness: [EnhancementEffectiveness]
    let processingTime: TimeInterval
    let appliedEnhancements: [Enhancement]
    
    var isEffective: Bool {
        overallImprovement > 0.1
    }
    
    var mostEffectiveEnhancement: EnhancementEffectiveness? {
        enhancementEffectiveness.max { $0.effectivenessScore < $1.effectivenessScore }
    }
    
    var leastEffectiveEnhancement: EnhancementEffectiveness? {
        enhancementEffectiveness.min { $0.effectivenessScore < $1.effectivenessScore }
    }
}

/// Individual enhancement effectiveness
struct EnhancementEffectiveness: Codable, Hashable {
    let enhancementType: EnhancementType
    let appliedIntensity: Float
    let effectivenessScore: Float
    let visualImprovementScore: Float
    let userSatisfactionPrediction: Float
    
    var isHighlyEffective: Bool {
        effectivenessScore > 0.8
    }
    
    var recommendedIntensityAdjustment: Float {
        if effectivenessScore < 0.5 {
            return appliedIntensity * 0.7 // Reduce intensity
        } else if effectivenessScore > 0.8 {
            return min(appliedIntensity * 1.2, 1.0) // Increase intensity
        } else {
            return appliedIntensity // Keep same intensity
        }
    }
}

// MARK: - User Learning and Preferences

/// User learning profile for personalization
struct UserLearningProfile: Codable {
    let userId: UUID
    var preferenceWeights: [EnhancementType: Float]
    var satisfactionHistory: [EnhancementFeedback]
    var enhancementUsageFrequency: [EnhancementType: Int]
    var averageSatisfactionScores: [EnhancementType: Float]
    var lastUpdated: Date
    
    init(userId: UUID) {
        self.userId = userId
        self.preferenceWeights = [:]
        self.satisfactionHistory = []
        self.enhancementUsageFrequency = [:]
        self.averageSatisfactionScores = [:]
        self.lastUpdated = Date()
    }
    
    mutating func updatePreferences(feedback: EnhancementFeedback) {
        // Update preference weights based on user feedback
        let currentWeight = preferenceWeights[feedback.enhancementType] ?? 0.5
        let adjustment = (feedback.satisfactionScore - 0.5) * 0.2
        preferenceWeights[feedback.enhancementType] = max(0.1, min(1.0, currentWeight + adjustment))
        
        // Update usage frequency
        enhancementUsageFrequency[feedback.enhancementType, default: 0] += 1
        
        // Update satisfaction scores
        let currentAverage = averageSatisfactionScores[feedback.enhancementType] ?? 0.5
        let count = Float(enhancementUsageFrequency[feedback.enhancementType] ?? 1)
        averageSatisfactionScores[feedback.enhancementType] = (currentAverage * (count - 1) + feedback.satisfactionScore) / count
        
        lastUpdated = Date()
    }
    
    mutating func updateEffectivenessData(feedback: EnhancementFeedback) {
        satisfactionHistory.append(feedback)
        
        // Keep only recent history (last 50 feedbacks)
        if satisfactionHistory.count > 50 {
            satisfactionHistory.removeFirst()
        }
    }
    
    func getPreferenceAdjustment(for enhancementType: EnhancementType) -> Float {
        return preferenceWeights[enhancementType] ?? 0.5
    }
    
    func getConfidenceAdjustment(for enhancementType: EnhancementType) -> Float {
        let usageCount = enhancementUsageFrequency[enhancementType] ?? 0
        let satisfactionScore = averageSatisfactionScores[enhancementType] ?? 0.5
        
        // Higher usage and satisfaction = higher confidence
        let usageBonus = min(Float(usageCount) * 0.05, 0.3)
        let satisfactionBonus = (satisfactionScore - 0.5) * 0.4
        
        return max(0.5, min(1.2, 1.0 + usageBonus + satisfactionBonus))
    }
    
    var mostPreferredEnhancements: [EnhancementType] {
        preferenceWeights
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }
    }
    
    var leastPreferredEnhancements: [EnhancementType] {
        preferenceWeights
            .sorted { $0.value < $1.value }
            .prefix(3)
            .map { $0.key }
    }
}

/// User feedback on enhancement effectiveness
struct EnhancementFeedback: Codable, Hashable {
    let id: UUID
    let userId: UUID
    let enhancementType: EnhancementType
    let appliedIntensity: Float
    let satisfactionScore: Float // 0.0 to 1.0
    let visualImprovementRating: Float // 0.0 to 1.0
    let wouldUseAgain: Bool
    let comments: String?
    let timestamp: Date
    let imageAnalysisId: UUID?
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        enhancementType: EnhancementType,
        appliedIntensity: Float,
        satisfactionScore: Float,
        visualImprovementRating: Float,
        wouldUseAgain: Bool,
        comments: String? = nil,
        timestamp: Date = Date(),
        imageAnalysisId: UUID? = nil
    ) {
        self.id = id
        self.userId = userId
        self.enhancementType = enhancementType
        self.appliedIntensity = appliedIntensity
        self.satisfactionScore = satisfactionScore
        self.visualImprovementRating = visualImprovementRating
        self.wouldUseAgain = wouldUseAgain
        self.comments = comments
        self.timestamp = timestamp
        self.imageAnalysisId = imageAnalysisId
    }
    
    var feedbackCategory: FeedbackCategory {
        switch satisfactionScore {
        case 0.8...1.0: return .excellent
        case 0.6..<0.8: return .good
        case 0.4..<0.6: return .neutral
        case 0.2..<0.4: return .poor
        default: return .terrible
        }
    }
}

/// Feedback categories
enum FeedbackCategory: String, Codable, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case neutral = "neutral"
    case poor = "poor"
    case terrible = "terrible"
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var emoji: String {
        switch self {
        case .excellent: return "😍"
        case .good: return "😊"
        case .neutral: return "😐"
        case .poor: return "😞"
        case .terrible: return "😡"
        }
    }
}

// MARK: - Recommendation History

/// Historical record of recommendations
struct RecommendationHistory: Codable, Hashable, Identifiable {
    let id: UUID
    let userId: UUID
    let imageAnalysisId: UUID
    let recommendations: [PersonalizedRecommendation]
    let appliedRecommendations: [UUID]
    let timestamp: Date
    let effectiveness: EffectivenessAnalysis?
    let userFeedback: [EnhancementFeedback]
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        imageAnalysisId: UUID,
        recommendations: [PersonalizedRecommendation],
        appliedRecommendations: [UUID] = [],
        timestamp: Date = Date(),
        effectiveness: EffectivenessAnalysis? = nil,
        userFeedback: [EnhancementFeedback] = []
    ) {
        self.id = id
        self.userId = userId
        self.imageAnalysisId = imageAnalysisId
        self.recommendations = recommendations
        self.appliedRecommendations = appliedRecommendations
        self.timestamp = timestamp
        self.effectiveness = effectiveness
        self.userFeedback = userFeedback
    }
    
    var appliedRecommendationObjects: [PersonalizedRecommendation] {
        recommendations.filter { appliedRecommendations.contains($0.id) }
    }
    
    var acceptanceRate: Float {
        guard !recommendations.isEmpty else { return 0.0 }
        return Float(appliedRecommendations.count) / Float(recommendations.count)
    }
    
    var overallSatisfaction: Float? {
        guard !userFeedback.isEmpty else { return nil }
        return userFeedback.map { $0.satisfactionScore }.reduce(0, +) / Float(userFeedback.count)
    }
}

// MARK: - Smart Enhancement Suggestions

/// Context-aware enhancement suggestion
struct SmartEnhancementSuggestion: Codable, Hashable {
    let enhancementType: EnhancementType
    let triggerConditions: [TriggerCondition]
    let adaptiveIntensity: AdaptiveIntensityRule
    let conflictingEnhancements: [EnhancementType]
    let synergisticEnhancements: [EnhancementType]
    let minimumImageQuality: Float
    let applicabilityScore: Float
    
    func isApplicable(to analysis: ImageAnalysisResult, userProfile: UserProfile?) -> Bool {
        // Check if image quality meets minimum requirements
        guard analysis.imageQuality.overallScore >= minimumImageQuality else { return false }
        
        // Check if trigger conditions are met
        let conditionsMet = triggerConditions.allSatisfy { condition in
            condition.isMet(by: analysis, userProfile: userProfile)
        }
        
        return conditionsMet
    }
    
    func calculateRecommendedIntensity(
        for analysis: ImageAnalysisResult,
        userProfile: UserProfile?
    ) -> Float {
        return adaptiveIntensity.calculateIntensity(for: analysis, userProfile: userProfile)
    }
}

/// Trigger condition for smart suggestions
struct TriggerCondition: Codable, Hashable {
    let type: TriggerType
    let parameter: String
    let threshold: Float
    let comparison: ComparisonOperator
    
    func isMet(by analysis: ImageAnalysisResult, userProfile: UserProfile?) -> Bool {
        let value = extractValue(from: analysis, userProfile: userProfile)
        return comparison.evaluate(value, threshold)
    }
    
    private func extractValue(from analysis: ImageAnalysisResult, userProfile: UserProfile?) -> Float {
        switch type {
        case .imageQuality:
            switch parameter {
            case "overall": return analysis.imageQuality.overallScore
            case "sharpness": return analysis.imageQuality.sharpness
            case "noise": return analysis.imageQuality.noise
            default: return 0.0
            }
        case .faceQuality:
            guard let face = analysis.primaryFace else { return 0.0 }
            switch parameter {
            case "lighting": return face.faceQuality.lighting
            case "pose": return face.faceQuality.pose
            case "expression": return face.faceQuality.expression
            default: return 0.0
            }
        case .sceneAnalysis:
            switch parameter {
            case "lighting_conditions":
                return analysis.sceneAnalysis.lightingConditions == .poor ? 1.0 : 0.0
            default: return 0.0
            }
        case .userPreference:
            return userProfile?.skinTone?.rawValue.hash.magnitude.truncatingRemainder(dividingBy: 1) ?? 0.5
        }
    }
}

/// Types of trigger conditions
enum TriggerType: String, Codable, CaseIterable {
    case imageQuality = "image_quality"
    case faceQuality = "face_quality"
    case sceneAnalysis = "scene_analysis"
    case userPreference = "user_preference"
}

/// Comparison operators for conditions
enum ComparisonOperator: String, Codable, CaseIterable {
    case greaterThan = "gt"
    case lessThan = "lt"
    case equalTo = "eq"
    case greaterThanOrEqual = "gte"
    case lessThanOrEqual = "lte"
    
    func evaluate(_ value: Float, _ threshold: Float) -> Bool {
        switch self {
        case .greaterThan: return value > threshold
        case .lessThan: return value < threshold
        case .equalTo: return abs(value - threshold) < 0.01
        case .greaterThanOrEqual: return value >= threshold
        case .lessThanOrEqual: return value <= threshold
        }
    }
}

/// Adaptive intensity calculation rules
struct AdaptiveIntensityRule: Codable, Hashable {
    let baseIntensity: Float
    let adjustmentFactors: [IntensityAdjustment]
    let minimumIntensity: Float
    let maximumIntensity: Float
    
    func calculateIntensity(for analysis: ImageAnalysisResult, userProfile: UserProfile?) -> Float {
        var intensity = baseIntensity
        
        for adjustment in adjustmentFactors {
            let factor = adjustment.calculateFactor(for: analysis, userProfile: userProfile)
            intensity *= factor
        }
        
        return max(minimumIntensity, min(maximumIntensity, intensity))
    }
}

/// Intensity adjustment factor
struct IntensityAdjustment: Codable, Hashable {
    let parameter: String
    let multiplier: Float
    let condition: TriggerCondition?
    
    func calculateFactor(for analysis: ImageAnalysisResult, userProfile: UserProfile?) -> Float {
        if let condition = condition {
            return condition.isMet(by: analysis, userProfile: userProfile) ? multiplier : 1.0
        }
        return multiplier
    }
}

// MARK: - Before/After Analysis

/// Before and after comparison result
struct BeforeAfterComparison: Codable, Hashable {
    let originalAnalysis: ImageAnalysisResult
    let enhancedAnalysis: ImageAnalysisResult
    let appliedEnhancements: [Enhancement]
    let improvements: [ImprovementMetric]
    let overallImprovementScore: Float
    let visualDifferenceScore: Float
    let processingTime: TimeInterval
    
    var hasSignificantImprovement: Bool {
        overallImprovementScore > 0.2
    }
    
    var mostImprovedAspect: ImprovementMetric? {
        improvements.max { $0.improvementScore < $1.improvementScore }
    }
}

/// Individual improvement metric
struct ImprovementMetric: Codable, Hashable {
    let aspect: QualityAspect
    let originalScore: Float
    let enhancedScore: Float
    let improvementScore: Float
    let relativeImprovement: Float
    
    var improvementCategory: ImprovementCategory {
        switch improvementScore {
        case 0.3...1.0: return .significant
        case 0.1..<0.3: return .moderate
        case 0.05..<0.1: return .slight
        default: return .negligible
        }
    }
}

/// Quality aspects that can be improved
enum QualityAspect: String, Codable, CaseIterable {
    case overall = "overall"
    case skinQuality = "skin_quality"
    case faceSymmetry = "face_symmetry"
    case eyeBrightness = "eye_brightness"
    case skinTone = "skin_tone"
    case lighting = "lighting"
    case sharpness = "sharpness"
    case beautyScore = "beauty_score"
    
    var displayName: String {
        switch self {
        case .overall: return "Overall Quality"
        case .skinQuality: return "Skin Quality"
        case .faceSymmetry: return "Face Symmetry"
        case .eyeBrightness: return "Eye Brightness"
        case .skinTone: return "Skin Tone"
        case .lighting: return "Lighting"
        case .sharpness: return "Sharpness"
        case .beautyScore: return "Beauty Score"
        }
    }
}

/// Categories of improvement
enum ImprovementCategory: String, Codable, CaseIterable {
    case significant = "significant"
    case moderate = "moderate"
    case slight = "slight"
    case negligible = "negligible"
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var color: UIColor {
        switch self {
        case .significant: return .systemGreen
        case .moderate: return .systemBlue
        case .slight: return .systemYellow
        case .negligible: return .systemGray
        }
    }
}