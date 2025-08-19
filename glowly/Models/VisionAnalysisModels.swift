//
//  VisionAnalysisModels.swift
//  Glowly
//
//  Enhanced data models for vision analysis and face detection results
//

import Foundation
import UIKit
import CoreGraphics

// MARK: - Comprehensive Analysis Results

/// Complete image analysis result combining all vision processing
struct ImageAnalysisResult: Codable, Hashable {
    let faces: [DetailedFaceDetectionResult]
    let imageQuality: ImageQualityResult
    let sceneAnalysis: SceneAnalysisResult
    let enhancementOpportunities: EnhancementOpportunitiesResult
    let processingTime: TimeInterval
    
    var hasFaces: Bool { !faces.isEmpty }
    var primaryFace: DetailedFaceDetectionResult? { faces.first }
    var faceCount: Int { faces.count }
    var isPortrait: Bool { sceneAnalysis.sceneType == .portrait }
    var overallQualityScore: Float {
        let faceScore = faces.first?.faceQuality.overallScore ?? 0.5
        return (imageQuality.overallScore + faceScore) / 2.0
    }
}

/// Enhanced face detection result with comprehensive analysis
struct DetailedFaceDetectionResult: Codable, Hashable, Identifiable {
    let id: UUID
    let faceIndex: Int
    let boundingBox: CGRect
    let normalizedBoundingBox: CGRect
    let confidence: Float
    let landmarks: DetailedFaceLandmarks?
    let faceQuality: DetailedFaceQuality
    let faceAnalysis: FaceCharacteristicsAnalysis
    let skinToneAnalysis: SkinToneAnalysisResult
    
    var isHighQuality: Bool { faceQuality.overallScore > 0.7 }
    var isSuitableForEnhancement: Bool { faceQuality.suitabilityForEnhancement > 0.6 }
    var dominantSkinTone: SkinTone { skinToneAnalysis.skinToneCategory }
}

/// Detailed facial landmarks with comprehensive points
struct DetailedFaceLandmarks: Codable, Hashable {
    // Eyes
    let leftEye: [CGPoint]
    let rightEye: [CGPoint]
    let leftPupil: CGPoint?
    let rightPupil: CGPoint?
    
    // Eyebrows
    let leftEyebrow: [CGPoint]
    let rightEyebrow: [CGPoint]
    
    // Nose
    let nose: [CGPoint]
    let noseCrest: [CGPoint]
    
    // Mouth
    let outerLips: [CGPoint]
    let innerLips: [CGPoint]
    
    // Face structure
    let faceContour: [CGPoint]
    let medianLine: [CGPoint]
    
    // Computed properties
    var eyeCenter: CGPoint? {
        guard let leftPupil = leftPupil, let rightPupil = rightPupil else { return nil }
        return CGPoint(
            x: (leftPupil.x + rightPupil.x) / 2,
            y: (leftPupil.y + rightPupil.y) / 2
        )
    }
    
    var mouthCenter: CGPoint? {
        guard !outerLips.isEmpty else { return nil }
        let sumX = outerLips.map { $0.x }.reduce(0, +)
        let sumY = outerLips.map { $0.y }.reduce(0, +)
        return CGPoint(
            x: sumX / CGFloat(outerLips.count),
            y: sumY / CGFloat(outerLips.count)
        )
    }
    
    var faceSymmetryScore: Float {
        // Calculate face symmetry based on landmark positions
        // This is a simplified calculation
        guard !faceContour.isEmpty else { return 0.5 }
        
        // Compare left and right halves
        let midPoint = faceContour.map { $0.x }.reduce(0, +) / CGFloat(faceContour.count)
        let leftPoints = faceContour.filter { $0.x < midPoint }
        let rightPoints = faceContour.filter { $0.x > midPoint }
        
        // Simplified symmetry score
        return leftPoints.count == rightPoints.count ? 0.9 : 0.7
    }
}

/// Enhanced face quality assessment
struct DetailedFaceQuality: Codable, Hashable {
    let overallScore: Float
    let lighting: Float
    let sharpness: Float
    let pose: Float
    let expression: Float
    let occlusion: Float
    let resolution: Float
    let suitabilityForEnhancement: Float
    
    init(
        overallScore: Float = 0.0,
        lighting: Float = 0.0,
        sharpness: Float = 0.0,
        pose: Float = 0.0,
        expression: Float = 0.0,
        occlusion: Float = 0.0,
        resolution: Float = 0.0,
        suitabilityForEnhancement: Float = 0.0
    ) {
        self.overallScore = overallScore
        self.lighting = lighting
        self.sharpness = sharpness
        self.pose = pose
        self.expression = expression
        self.occlusion = occlusion
        self.resolution = resolution
        self.suitabilityForEnhancement = suitabilityForEnhancement
    }
    
    var qualityCategory: QualityCategory {
        switch overallScore {
        case 0.8...1.0: return .excellent
        case 0.6..<0.8: return .good
        case 0.4..<0.6: return .fair
        default: return .poor
        }
    }
    
    var improvementAreas: [QualityImprovementArea] {
        var areas: [QualityImprovementArea] = []
        
        if lighting < 0.6 { areas.append(.lighting) }
        if sharpness < 0.6 { areas.append(.sharpness) }
        if pose < 0.7 { areas.append(.pose) }
        if occlusion < 0.8 { areas.append(.occlusion) }
        if resolution < 0.5 { areas.append(.resolution) }
        
        return areas
    }
}

// MARK: - Skin Tone Analysis

/// Comprehensive skin tone analysis result
struct SkinToneAnalysisResult: Codable, Hashable {
    let dominantColor: CodableColor
    let skinToneCategory: SkinTone
    let undertone: SkinUndertone
    let colorSamples: [CodableColor]
    let confidence: Float
    
    var recommendedEnhancementIntensity: Float {
        // Different skin tones may benefit from different enhancement intensities
        switch skinToneCategory {
        case .veryLight: return 0.2
        case .light: return 0.3
        case .medium: return 0.4
        case .tan: return 0.5
        case .dark: return 0.6
        case .veryDark: return 0.7
        }
    }
    
    var isHighConfidence: Bool { confidence > 0.8 }
}

/// Skin undertone classification
enum SkinUndertone: String, Codable, CaseIterable {
    case cool = "cool"
    case warm = "warm"
    case neutral = "neutral"
    case olive = "olive"
    
    var displayName: String {
        switch self {
        case .cool: return "Cool"
        case .warm: return "Warm"
        case .neutral: return "Neutral"
        case .olive: return "Olive"
        }
    }
    
    var enhancementAdjustments: [String: Float] {
        switch self {
        case .cool:
            return ["blue_boost": 0.1, "red_reduce": -0.05]
        case .warm:
            return ["yellow_boost": 0.1, "blue_reduce": -0.05]
        case .neutral:
            return [:]
        case .olive:
            return ["green_adjust": 0.05, "yellow_boost": 0.08]
        }
    }
}

// MARK: - Face Characteristics

/// Detailed face characteristics analysis
struct FaceCharacteristicsAnalysis: Codable, Hashable {
    let age: AgeCategory
    let gender: GenderCategory
    let expression: ExpressionType
    let eyeOpenness: Float // 0.0 = closed, 1.0 = fully open
    let mouthOpenness: Float // 0.0 = closed, 1.0 = wide open
    let headPose: HeadPose
    
    var isNeutralExpression: Bool { expression == .neutral }
    var hasGoodPose: Bool { headPose.isNearFrontal }
    var eyesWellOpen: Bool { eyeOpenness > 0.7 }
}

/// Age category classification
enum AgeCategory: String, Codable, CaseIterable {
    case child = "child"
    case teenager = "teenager"
    case youngAdult = "young_adult"
    case adult = "adult"
    case senior = "senior"
    
    var displayName: String {
        switch self {
        case .child: return "Child"
        case .teenager: return "Teenager"
        case .youngAdult: return "Young Adult"
        case .adult: return "Adult"
        case .senior: return "Senior"
        }
    }
    
    var recommendedEnhancements: [EnhancementType] {
        switch self {
        case .child:
            return [.eyeBrightening, .autoEnhance]
        case .teenager:
            return [.skinSmoothing, .blemishRemoval, .eyeBrightening]
        case .youngAdult, .adult:
            return [.skinSmoothing, .eyeBrightening, .teethWhitening, .lipEnhancement]
        case .senior:
            return [.skinSmoothing, .eyeBrightening, .ageReduction]
        }
    }
}

/// Gender category (for enhancement recommendations)
enum GenderCategory: String, Codable, CaseIterable {
    case male = "male"
    case female = "female"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .unknown: return "Unknown"
        }
    }
}

/// Expression type detection
enum ExpressionType: String, Codable, CaseIterable {
    case neutral = "neutral"
    case happy = "happy"
    case sad = "sad"
    case surprised = "surprised"
    case angry = "angry"
    case disgusted = "disgusted"
    case fearful = "fearful"
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var enhancementRecommendations: [EnhancementType] {
        switch self {
        case .happy:
            return [.teethWhitening, .eyeBrightening, .lipEnhancement]
        case .neutral:
            return [.skinSmoothing, .eyeBrightening, .autoEnhance]
        default:
            return [.autoEnhance, .skinSmoothing]
        }
    }
}

/// Head pose estimation
struct HeadPose: Codable, Hashable {
    let yaw: Float   // Left-right rotation (-90 to 90 degrees)
    let pitch: Float // Up-down rotation (-90 to 90 degrees)
    let roll: Float  // Tilt rotation (-180 to 180 degrees)
    
    var isNearFrontal: Bool {
        abs(yaw) < 15 && abs(pitch) < 15 && abs(roll) < 15
    }
    
    var poseCategory: PoseCategory {
        if isNearFrontal { return .frontal }
        if abs(yaw) > 45 { return .profile }
        if abs(pitch) > 30 { return .extreme }
        return .moderate
    }
}

/// Pose quality categories
enum PoseCategory: String, Codable, CaseIterable {
    case frontal = "frontal"
    case moderate = "moderate"
    case profile = "profile"
    case extreme = "extreme"
    
    var suitabilityScore: Float {
        switch self {
        case .frontal: return 1.0
        case .moderate: return 0.8
        case .profile: return 0.6
        case .extreme: return 0.3
        }
    }
}

// MARK: - Image Quality Analysis

/// Comprehensive image quality assessment
struct ImageQualityResult: Codable, Hashable {
    let overallScore: Float
    let resolution: Float
    let sharpness: Float
    let noise: Float
    let exposure: Float
    
    var qualityLevel: QualityLevel {
        switch overallScore {
        case 0.8...1.0: return .excellent
        case 0.6..<0.8: return .good
        case 0.4..<0.6: return .fair
        default: return .poor
        }
    }
    
    var needsImprovement: Bool { overallScore < 0.6 }
}

/// Quality level enumeration
enum QualityLevel: String, Codable, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var color: UIColor {
        switch self {
        case .excellent: return .systemGreen
        case .good: return .systemBlue
        case .fair: return .systemOrange
        case .poor: return .systemRed
        }
    }
}

/// Quality categories for assessment
enum QualityCategory: String, Codable, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    
    var displayName: String {
        rawValue.capitalized
    }
}

/// Areas that can be improved for better quality
enum QualityImprovementArea: String, Codable, CaseIterable {
    case lighting = "lighting"
    case sharpness = "sharpness"
    case pose = "pose"
    case occlusion = "occlusion"
    case resolution = "resolution"
    case expression = "expression"
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var improvementSuggestion: String {
        switch self {
        case .lighting:
            return "Improve lighting conditions or adjust exposure"
        case .sharpness:
            return "Use better focus or reduce camera shake"
        case .pose:
            return "Position face more directly toward camera"
        case .occlusion:
            return "Remove objects blocking the face"
        case .resolution:
            return "Use higher quality camera settings"
        case .expression:
            return "Try a more neutral or pleasant expression"
        }
    }
}

// MARK: - Scene Analysis

/// Scene analysis result
struct SceneAnalysisResult: Codable, Hashable {
    let sceneType: SceneType
    let lightingConditions: LightingConditions
    let backgroundComplexity: BackgroundComplexity
    let colorPalette: [String]
    
    var isOptimalForPortrait: Bool {
        sceneType == .portrait && 
        lightingConditions != .poor && 
        backgroundComplexity != .veryComplex
    }
}

/// Types of scenes detected
enum SceneType: String, Codable, CaseIterable {
    case portrait = "portrait"
    case group = "group"
    case selfie = "selfie"
    case landscape = "landscape"
    case indoor = "indoor"
    case outdoor = "outdoor"
    case unknown = "unknown"
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var recommendedEnhancements: [EnhancementType] {
        switch self {
        case .portrait, .selfie:
            return [.skinSmoothing, .eyeBrightening, .portraitMode]
        case .group:
            return [.autoEnhance, .eyeBrightening]
        case .outdoor:
            return [.autoEnhance, .clarity, .saturation]
        case .indoor:
            return [.brightness, .warmth, .autoEnhance]
        default:
            return [.autoEnhance]
        }
    }
}

/// Lighting condition assessment
enum LightingConditions: String, Codable, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    case backlit = "backlit"
    case harsh = "harsh"
    case lowLight = "low_light"
    
    var displayName: String {
        switch self {
        case .lowLight: return "Low Light"
        default: return rawValue.capitalized
        }
    }
    
    var correctionSuggestions: [EnhancementType] {
        switch self {
        case .poor, .lowLight:
            return [.brightness, .exposure, .shadows]
        case .backlit:
            return [.shadows, .highlights, .exposure]
        case .harsh:
            return [.highlights, .shadows, .warmth]
        default:
            return []
        }
    }
}

/// Background complexity assessment
enum BackgroundComplexity: String, Codable, CaseIterable {
    case simple = "simple"
    case moderate = "moderate"
    case complex = "complex"
    case veryComplex = "very_complex"
    
    var displayName: String {
        switch self {
        case .veryComplex: return "Very Complex"
        default: return rawValue.capitalized
        }
    }
    
    var backgroundBlurRecommended: Bool {
        self == .complex || self == .veryComplex
    }
}

// MARK: - Enhancement Opportunities

/// Enhancement opportunities analysis result
struct EnhancementOpportunitiesResult: Codable, Hashable {
    let opportunities: [EnhancementOpportunity]
    let overallScore: Float
    let primaryRecommendations: [EnhancementOpportunity]
    
    var hasHighValueOpportunities: Bool {
        opportunities.contains { $0.confidence > 0.8 }
    }
    
    var topOpportunity: EnhancementOpportunity? {
        opportunities.max { $0.confidence < $1.confidence }
    }
}

/// Individual enhancement opportunity
struct EnhancementOpportunity: Codable, Hashable {
    let type: EnhancementType
    let confidence: Float
    let recommendedIntensity: Float
    let reasoning: String
    
    var isPrimaryRecommendation: Bool { confidence > 0.8 }
    var isSecondaryRecommendation: Bool { confidence > 0.6 && confidence <= 0.8 }
}

// MARK: - Helper Types

/// Codable wrapper for UIColor
struct CodableColor: Codable, Hashable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double
    
    init(_ color: UIColor) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.alpha = Double(a)
    }
    
    var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

// MARK: - Beauty Analysis Models

/// Beauty score calculation result
struct BeautyAnalysisResult: Codable, Hashable {
    let overallScore: Float
    let symmetryScore: Float
    let proportionScore: Float
    let featureQualityScore: Float
    let skinQualityScore: Float
    let enhancementPotential: Float
    
    var beautyCategory: BeautyCategory {
        switch overallScore {
        case 0.8...1.0: return .high
        case 0.6..<0.8: return .good
        case 0.4..<0.6: return .average
        default: return .needsImprovement
        }
    }
}

/// Beauty assessment categories
enum BeautyCategory: String, Codable, CaseIterable {
    case high = "high"
    case good = "good"
    case average = "average"
    case needsImprovement = "needs_improvement"
    
    var displayName: String {
        switch self {
        case .needsImprovement: return "Needs Improvement"
        default: return rawValue.capitalized
        }
    }
}

/// ML Model performance metrics
struct ModelPerformanceMetrics: Codable, Hashable {
    let inferenceTime: TimeInterval
    let confidence: Float
    let memoryUsage: Int64
    let gpuAccelerated: Bool
    let modelVersion: String
    
    var isOptimalPerformance: Bool {
        inferenceTime < 1.0 && confidence > 0.7
    }
}