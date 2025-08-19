//
//  ManualRetouchingModels.swift
//  Glowly
//
//  Data models for manual retouching tools and operations
//

import Foundation
import UIKit
import CoreGraphics

// MARK: - Manual Retouching Tool Data

/// Brush configuration for manual retouching tools
struct BrushConfiguration: Codable, Hashable {
    let size: Float // 1.0 to 100.0
    let hardness: Float // 0.0 to 1.0 (0 = soft, 1 = hard)
    let opacity: Float // 0.0 to 1.0
    let flow: Float // 0.0 to 1.0
    let spacing: Float // 0.0 to 1.0
    let blendMode: BlendMode
    
    init(
        size: Float = 20.0,
        hardness: Float = 0.5,
        opacity: Float = 1.0,
        flow: Float = 1.0,
        spacing: Float = 0.25,
        blendMode: BlendMode = .normal
    ) {
        self.size = size
        self.hardness = hardness
        self.opacity = opacity
        self.flow = flow
        self.spacing = spacing
        self.blendMode = blendMode
    }
}

/// Blend modes for brush operations
enum BlendMode: String, Codable, CaseIterable {
    case normal = "normal"
    case overlay = "overlay"
    case softLight = "soft_light"
    case hardLight = "hard_light"
    case multiply = "multiply"
    case screen = "screen"
    case colorDodge = "color_dodge"
    case colorBurn = "color_burn"
    case lighten = "lighten"
    case darken = "darken"
    
    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .overlay: return "Overlay"
        case .softLight: return "Soft Light"
        case .hardLight: return "Hard Light"
        case .multiply: return "Multiply"
        case .screen: return "Screen"
        case .colorDodge: return "Color Dodge"
        case .colorBurn: return "Color Burn"
        case .lighten: return "Lighten"
        case .darken: return "Darken"
        }
    }
}

/// Manual retouching operation that can be applied with a brush
struct ManualRetouchingOperation: Identifiable, Codable {
    let id: UUID
    let enhancementType: EnhancementType
    let brushConfiguration: BrushConfiguration
    let touchPoints: [TouchPoint]
    let intensity: Float
    let parameters: [String: Float]
    let timestamp: Date
    let processingTime: TimeInterval
    
    init(
        id: UUID = UUID(),
        enhancementType: EnhancementType,
        brushConfiguration: BrushConfiguration,
        touchPoints: [TouchPoint] = [],
        intensity: Float,
        parameters: [String: Float] = [:],
        timestamp: Date = Date(),
        processingTime: TimeInterval = 0
    ) {
        self.id = id
        self.enhancementType = enhancementType
        self.brushConfiguration = brushConfiguration
        self.touchPoints = touchPoints
        self.intensity = intensity
        self.parameters = parameters
        self.timestamp = timestamp
        self.processingTime = processingTime
    }
}

/// Touch point for brush-based retouching
struct TouchPoint: Codable, Hashable {
    let location: CGPoint
    let pressure: Float // 0.0 to 1.0
    let timestamp: TimeInterval
    
    init(location: CGPoint, pressure: Float = 1.0, timestamp: TimeInterval = CACurrentMediaTime()) {
        self.location = location
        self.pressure = pressure
        self.timestamp = timestamp
    }
}

// MARK: - Face Detection and Regions

/// Face regions for targeted enhancements
enum FaceRegion: String, Codable, CaseIterable {
    case skin = "skin"
    case eyes = "eyes"
    case leftEye = "left_eye"
    case rightEye = "right_eye"
    case eyebrows = "eyebrows"
    case nose = "nose"
    case mouth = "mouth"
    case lips = "lips"
    case teeth = "teeth"
    case jawline = "jawline"
    case forehead = "forehead"
    case cheeks = "cheeks"
    case chin = "chin"
    case hair = "hair"
    
    var displayName: String {
        switch self {
        case .skin: return "Skin"
        case .eyes: return "Eyes"
        case .leftEye: return "Left Eye"
        case .rightEye: return "Right Eye"
        case .eyebrows: return "Eyebrows"
        case .nose: return "Nose"
        case .mouth: return "Mouth"
        case .lips: return "Lips"
        case .teeth: return "Teeth"
        case .jawline: return "Jawline"
        case .forehead: return "Forehead"
        case .cheeks: return "Cheeks"
        case .chin: return "Chin"
        case .hair: return "Hair"
        }
    }
}

/// Detected face regions with boundaries
struct DetectedFaceRegions: Codable {
    let faceRect: CGRect
    let regions: [FaceRegion: CGRect]
    let landmarks: [FaceLandmark]
    let confidence: Float
    
    init(
        faceRect: CGRect,
        regions: [FaceRegion: CGRect] = [:],
        landmarks: [FaceLandmark] = [],
        confidence: Float = 0.0
    ) {
        self.faceRect = faceRect
        self.regions = regions
        self.landmarks = landmarks
        self.confidence = confidence
    }
}

/// Face landmark points for precise retouching
struct FaceLandmark: Codable, Hashable {
    let type: LandmarkType
    let points: [CGPoint]
    let confidence: Float
    
    init(type: LandmarkType, points: [CGPoint], confidence: Float = 1.0) {
        self.type = type
        self.points = points
        self.confidence = confidence
    }
}

/// Types of face landmarks
enum LandmarkType: String, Codable, CaseIterable {
    case leftEyeContour = "left_eye_contour"
    case rightEyeContour = "right_eye_contour"
    case leftEyebrow = "left_eyebrow"
    case rightEyebrow = "right_eyebrow"
    case noseContour = "nose_contour"
    case noseTip = "nose_tip"
    case mouthContour = "mouth_contour"
    case lipContour = "lip_contour"
    case jawContour = "jaw_contour"
    case faceContour = "face_contour"
    case hairline = "hairline"
}

// MARK: - Color and Texture Data

/// Color palette for color-changing tools
struct ColorPalette: Codable, Hashable {
    let name: String
    let colors: [ColorInfo]
    let category: ColorCategory
    
    init(name: String, colors: [ColorInfo], category: ColorCategory) {
        self.name = name
        self.colors = colors
        self.category = category
    }
}

/// Individual color information
struct ColorInfo: Codable, Hashable {
    let name: String
    let red: Float
    let green: Float
    let blue: Float
    let alpha: Float
    
    init(name: String, red: Float, green: Float, blue: Float, alpha: Float = 1.0) {
        self.name = name
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
    
    var uiColor: UIColor {
        return UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
    }
    
    init(name: String, uiColor: UIColor) {
        self.name = name
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        self.red = Float(red)
        self.green = Float(green)
        self.blue = Float(blue)
        self.alpha = Float(alpha)
    }
}

/// Color categories for organization
enum ColorCategory: String, Codable, CaseIterable {
    case natural = "natural"
    case vibrant = "vibrant"
    case pastel = "pastel"
    case bold = "bold"
    case warm = "warm"
    case cool = "cool"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

// MARK: - Mesh Deformation Data

/// Mesh deformation for face and body reshaping
struct DeformationMesh: Codable {
    let originalPoints: [CGPoint]
    let deformedPoints: [CGPoint]
    let triangles: [Triangle]
    let bounds: CGRect
    
    init(originalPoints: [CGPoint], deformedPoints: [CGPoint], triangles: [Triangle], bounds: CGRect) {
        self.originalPoints = originalPoints
        self.deformedPoints = deformedPoints
        self.triangles = triangles
        self.bounds = bounds
    }
}

/// Triangle for mesh triangulation
struct Triangle: Codable, Hashable {
    let pointIndex1: Int
    let pointIndex2: Int
    let pointIndex3: Int
    
    init(_ p1: Int, _ p2: Int, _ p3: Int) {
        self.pointIndex1 = p1
        self.pointIndex2 = p2
        self.pointIndex3 = p3
    }
}

// MARK: - Tool State Management

/// State of a manual retouching tool
struct ToolState: Codable {
    let toolType: EnhancementType
    let isActive: Bool
    let settings: ToolSettings
    let currentBrush: BrushConfiguration
    let selectedRegion: FaceRegion?
    let maskData: Data?
    
    init(
        toolType: EnhancementType,
        isActive: Bool = false,
        settings: ToolSettings = ToolSettings(),
        currentBrush: BrushConfiguration = BrushConfiguration(),
        selectedRegion: FaceRegion? = nil,
        maskData: Data? = nil
    ) {
        self.toolType = toolType
        self.isActive = isActive
        self.settings = settings
        self.currentBrush = currentBrush
        self.selectedRegion = selectedRegion
        self.maskData = maskData
    }
}

/// Tool-specific settings
struct ToolSettings: Codable {
    var parameters: [String: Float]
    var colorSettings: [String: ColorInfo]
    var enabledFeatures: [String: Bool]
    
    init(
        parameters: [String: Float] = [:],
        colorSettings: [String: ColorInfo] = [:],
        enabledFeatures: [String: Bool] = [:]
    ) {
        self.parameters = parameters
        self.colorSettings = colorSettings
        self.enabledFeatures = enabledFeatures
    }
}

// MARK: - Processing Results

/// Result of a manual retouching operation
struct ManualRetouchingResult: Codable {
    let operationId: UUID
    let enhancementType: EnhancementType
    let processedImageData: Data?
    let maskData: Data?
    let processingTime: TimeInterval
    let success: Bool
    let errorMessage: String?
    let qualityMetrics: ProcessingQualityMetrics?
    
    init(
        operationId: UUID,
        enhancementType: EnhancementType,
        processedImageData: Data? = nil,
        maskData: Data? = nil,
        processingTime: TimeInterval,
        success: Bool,
        errorMessage: String? = nil,
        qualityMetrics: ProcessingQualityMetrics? = nil
    ) {
        self.operationId = operationId
        self.enhancementType = enhancementType
        self.processedImageData = processedImageData
        self.maskData = maskData
        self.processingTime = processingTime
        self.success = success
        self.errorMessage = errorMessage
        self.qualityMetrics = qualityMetrics
    }
}

/// Quality metrics for processing results
struct ProcessingQualityMetrics: Codable {
    let overallQuality: Float // 0.0 to 1.0
    let naturalness: Float // 0.0 to 1.0
    let sharpness: Float // 0.0 to 1.0
    let colorAccuracy: Float // 0.0 to 1.0
    let artifactLevel: Float // 0.0 to 1.0 (lower is better)
    
    init(
        overallQuality: Float,
        naturalness: Float,
        sharpness: Float,
        colorAccuracy: Float,
        artifactLevel: Float
    ) {
        self.overallQuality = overallQuality
        self.naturalness = naturalness
        self.sharpness = sharpness
        self.colorAccuracy = colorAccuracy
        self.artifactLevel = artifactLevel
    }
}

// MARK: - Predefined Color Palettes

extension ColorPalette {
    
    /// Natural eye colors
    static let naturalEyeColors = ColorPalette(
        name: "Natural Eye Colors",
        colors: [
            ColorInfo(name: "Brown", red: 0.35, green: 0.20, blue: 0.10),
            ColorInfo(name: "Hazel", red: 0.43, green: 0.30, blue: 0.13),
            ColorInfo(name: "Green", red: 0.20, green: 0.50, blue: 0.20),
            ColorInfo(name: "Blue", red: 0.20, green: 0.40, blue: 0.70),
            ColorInfo(name: "Gray", red: 0.40, green: 0.45, blue: 0.50),
            ColorInfo(name: "Dark Brown", red: 0.15, green: 0.10, blue: 0.05)
        ],
        category: .natural
    )
    
    /// Vibrant eye colors
    static let vibrantEyeColors = ColorPalette(
        name: "Vibrant Eye Colors",
        colors: [
            ColorInfo(name: "Electric Blue", red: 0.0, green: 0.7, blue: 1.0),
            ColorInfo(name: "Emerald Green", red: 0.0, green: 0.8, blue: 0.4),
            ColorInfo(name: "Violet", red: 0.6, green: 0.2, blue: 0.8),
            ColorInfo(name: "Golden Yellow", red: 1.0, green: 0.8, blue: 0.0),
            ColorInfo(name: "Silver", red: 0.7, green: 0.7, blue: 0.8),
            ColorInfo(name: "Turquoise", red: 0.0, green: 0.8, blue: 0.8)
        ],
        category: .vibrant
    )
    
    /// Natural hair colors
    static let naturalHairColors = ColorPalette(
        name: "Natural Hair Colors",
        colors: [
            ColorInfo(name: "Black", red: 0.05, green: 0.05, blue: 0.05),
            ColorInfo(name: "Dark Brown", red: 0.15, green: 0.10, blue: 0.08),
            ColorInfo(name: "Brown", red: 0.35, green: 0.25, blue: 0.15),
            ColorInfo(name: "Light Brown", red: 0.50, green: 0.35, blue: 0.20),
            ColorInfo(name: "Blonde", red: 0.85, green: 0.75, blue: 0.50),
            ColorInfo(name: "Red", red: 0.60, green: 0.25, blue: 0.15),
            ColorInfo(name: "Auburn", red: 0.50, green: 0.20, blue: 0.10),
            ColorInfo(name: "Gray", red: 0.50, green: 0.50, blue: 0.50),
            ColorInfo(name: "White", red: 0.95, green: 0.95, blue: 0.95)
        ],
        category: .natural
    )
    
    /// Natural lip colors
    static let naturalLipColors = ColorPalette(
        name: "Natural Lip Colors",
        colors: [
            ColorInfo(name: "Rose", red: 0.90, green: 0.60, blue: 0.60),
            ColorInfo(name: "Pink", red: 0.95, green: 0.70, blue: 0.75),
            ColorInfo(name: "Coral", red: 0.95, green: 0.65, blue: 0.50),
            ColorInfo(name: "Berry", red: 0.70, green: 0.30, blue: 0.40),
            ColorInfo(name: "Nude", red: 0.85, green: 0.65, blue: 0.55),
            ColorInfo(name: "Mauve", red: 0.75, green: 0.55, blue: 0.60)
        ],
        category: .natural
    )
}