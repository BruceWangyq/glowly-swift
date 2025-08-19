//
//  FilterModels.swift
//  Glowly
//
//  Comprehensive filter and beauty effects data models
//

import Foundation
import SwiftUI
import CoreImage

// MARK: - Beauty Filter Models

/// Represents a beauty filter that can be applied to photos
struct BeautyFilter: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let displayName: String
    let description: String
    let category: FilterCategory
    let style: FilterStyle
    let intensity: Float
    let isPremium: Bool
    let isPopular: Bool
    let isTrending: Bool
    let downloadCount: Int
    let rating: Float
    let thumbnailName: String?
    let previewImageName: String?
    let authorInfo: FilterAuthor?
    let socialMetadata: FilterSocialMetadata
    let processingConfig: FilterProcessingConfig
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        displayName: String,
        description: String,
        category: FilterCategory,
        style: FilterStyle,
        intensity: Float = 1.0,
        isPremium: Bool = false,
        isPopular: Bool = false,
        isTrending: Bool = false,
        downloadCount: Int = 0,
        rating: Float = 0.0,
        thumbnailName: String? = nil,
        previewImageName: String? = nil,
        authorInfo: FilterAuthor? = nil,
        socialMetadata: FilterSocialMetadata = FilterSocialMetadata(),
        processingConfig: FilterProcessingConfig,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.description = description
        self.category = category
        self.style = style
        self.intensity = intensity
        self.isPremium = isPremium
        self.isPopular = isPopular
        self.isTrending = isTrending
        self.downloadCount = downloadCount
        self.rating = rating
        self.thumbnailName = thumbnailName
        self.previewImageName = previewImageName
        self.authorInfo = authorInfo
        self.socialMetadata = socialMetadata
        self.processingConfig = processingConfig
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Filter categories for organization and discovery
enum FilterCategory: String, Codable, CaseIterable {
    case warm = "warm"
    case cool = "cool"
    case cinematic = "cinematic"
    case vintage = "vintage"
    case portrait = "portrait"
    case natural = "natural"
    case dramatic = "dramatic"
    case blackAndWhite = "black_and_white"
    case colorPop = "color_pop"
    case artistic = "artistic"
    case seasonal = "seasonal"
    case trending = "trending"
    
    var displayName: String {
        switch self {
        case .warm: return "Warm"
        case .cool: return "Cool"
        case .cinematic: return "Cinematic"
        case .vintage: return "Vintage"
        case .portrait: return "Portrait"
        case .natural: return "Natural"
        case .dramatic: return "Dramatic"
        case .blackAndWhite: return "B&W"
        case .colorPop: return "Color Pop"
        case .artistic: return "Artistic"
        case .seasonal: return "Seasonal"
        case .trending: return "Trending"
        }
    }
    
    var icon: String {
        switch self {
        case .warm: return "sun.max"
        case .cool: return "snowflake"
        case .cinematic: return "film"
        case .vintage: return "camera.vintage"
        case .portrait: return "person.circle"
        case .natural: return "leaf"
        case .dramatic: return "bolt"
        case .blackAndWhite: return "circle.lefthalf.filled"
        case .colorPop: return "paintbrush"
        case .artistic: return "paintpalette"
        case .seasonal: return "calendar"
        case .trending: return "chart.line.uptrend.xyaxis"
        }
    }
    
    var color: Color {
        switch self {
        case .warm: return .orange
        case .cool: return .blue
        case .cinematic: return .indigo
        case .vintage: return .brown
        case .portrait: return .pink
        case .natural: return .green
        case .dramatic: return .red
        case .blackAndWhite: return .gray
        case .colorPop: return .purple
        case .artistic: return .mint
        case .seasonal: return .yellow
        case .trending: return .cyan
        }
    }
}

/// Filter styles for different aesthetic approaches
enum FilterStyle: String, Codable, CaseIterable {
    case goldenHour = "golden_hour"
    case sunset = "sunset"
    case honey = "honey"
    case amber = "amber"
    case bronze = "bronze"
    case arctic = "arctic"
    case winter = "winter"
    case iceBlue = "ice_blue"
    case silver = "silver"
    case platinum = "platinum"
    case filmNoir = "film_noir"
    case vintageFilm = "vintage_film"
    case blockbuster = "blockbuster"
    case dramaticLighting = "dramatic_lighting"
    case retro = "retro"
    case sepia = "sepia"
    case oldFilm = "old_film"
    case polaroid = "polaroid"
    case fadedMemories = "faded_memories"
    case professionalHeadshot = "professional_headshot"
    case softPortrait = "soft_portrait"
    case studioLighting = "studio_lighting"
    case fresh = "fresh"
    case clean = "clean"
    case organic = "organic"
    case minimal = "minimal"
    
    var displayName: String {
        switch self {
        case .goldenHour: return "Golden Hour"
        case .sunset: return "Sunset"
        case .honey: return "Honey"
        case .amber: return "Amber"
        case .bronze: return "Bronze"
        case .arctic: return "Arctic"
        case .winter: return "Winter"
        case .iceBlue: return "Ice Blue"
        case .silver: return "Silver"
        case .platinum: return "Platinum"
        case .filmNoir: return "Film Noir"
        case .vintageFilm: return "Vintage Film"
        case .blockbuster: return "Blockbuster"
        case .dramaticLighting: return "Dramatic Lighting"
        case .retro: return "Retro"
        case .sepia: return "Sepia"
        case .oldFilm: return "Old Film"
        case .polaroid: return "Polaroid"
        case .fadedMemories: return "Faded Memories"
        case .professionalHeadshot: return "Professional Headshot"
        case .softPortrait: return "Soft Portrait"
        case .studioLighting: return "Studio Lighting"
        case .fresh: return "Fresh"
        case .clean: return "Clean"
        case .organic: return "Organic"
        case .minimal: return "Minimal"
        }
    }
}

/// Filter author information for attribution
struct FilterAuthor: Codable, Hashable {
    let id: UUID
    let name: String
    let displayName: String
    let profileImageName: String?
    let isVerified: Bool
    let followerCount: Int
    let filterCount: Int
    
    init(
        id: UUID = UUID(),
        name: String,
        displayName: String,
        profileImageName: String? = nil,
        isVerified: Bool = false,
        followerCount: Int = 0,
        filterCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.profileImageName = profileImageName
        self.isVerified = isVerified
        self.followerCount = followerCount
        self.filterCount = filterCount
    }
}

/// Social metadata for filter discovery and sharing
struct FilterSocialMetadata: Codable, Hashable {
    let likeCount: Int
    let shareCount: Int
    let saveCount: Int
    let commentCount: Int
    let tags: [String]
    let relatedFilters: [UUID]
    
    init(
        likeCount: Int = 0,
        shareCount: Int = 0,
        saveCount: Int = 0,
        commentCount: Int = 0,
        tags: [String] = [],
        relatedFilters: [UUID] = []
    ) {
        self.likeCount = likeCount
        self.shareCount = shareCount
        self.saveCount = saveCount
        self.commentCount = commentCount
        self.tags = tags
        self.relatedFilters = relatedFilters
    }
}

/// Processing configuration for filter application
struct FilterProcessingConfig: Codable, Hashable {
    let adjustments: FilterAdjustments
    let blendMode: FilterBlendMode
    let maskingConfig: FilterMaskingConfig?
    let complexityLevel: FilterComplexity
    let gpuAccelerated: Bool
    let preserveOriginalColors: Bool
    let faceAware: Bool
    
    init(
        adjustments: FilterAdjustments,
        blendMode: FilterBlendMode = .normal,
        maskingConfig: FilterMaskingConfig? = nil,
        complexityLevel: FilterComplexity = .medium,
        gpuAccelerated: Bool = true,
        preserveOriginalColors: Bool = false,
        faceAware: Bool = false
    ) {
        self.adjustments = adjustments
        self.blendMode = blendMode
        self.maskingConfig = maskingConfig
        self.complexityLevel = complexityLevel
        self.gpuAccelerated = gpuAccelerated
        self.preserveOriginalColors = preserveOriginalColors
        self.faceAware = faceAware
    }
}

/// Color and tone adjustments for filters
struct FilterAdjustments: Codable, Hashable {
    let brightness: Float
    let contrast: Float
    let saturation: Float
    let warmth: Float
    let exposure: Float
    let highlights: Float
    let shadows: Float
    let clarity: Float
    let vibrance: Float
    let gamma: Float
    let hueShift: Float
    let colorGrading: ColorGrading?
    
    init(
        brightness: Float = 0.0,
        contrast: Float = 0.0,
        saturation: Float = 0.0,
        warmth: Float = 0.0,
        exposure: Float = 0.0,
        highlights: Float = 0.0,
        shadows: Float = 0.0,
        clarity: Float = 0.0,
        vibrance: Float = 0.0,
        gamma: Float = 1.0,
        hueShift: Float = 0.0,
        colorGrading: ColorGrading? = nil
    ) {
        self.brightness = brightness
        self.contrast = contrast
        self.saturation = saturation
        self.warmth = warmth
        self.exposure = exposure
        self.highlights = highlights
        self.shadows = shadows
        self.clarity = clarity
        self.vibrance = vibrance
        self.gamma = gamma
        self.hueShift = hueShift
        self.colorGrading = colorGrading
    }
}

/// Color grading configuration
struct ColorGrading: Codable, Hashable {
    let highlightColor: ColorVector
    let midtoneColor: ColorVector
    let shadowColor: ColorVector
    let highlightIntensity: Float
    let midtoneIntensity: Float
    let shadowIntensity: Float
    
    init(
        highlightColor: ColorVector = ColorVector(r: 1.0, g: 1.0, b: 1.0),
        midtoneColor: ColorVector = ColorVector(r: 1.0, g: 1.0, b: 1.0),
        shadowColor: ColorVector = ColorVector(r: 1.0, g: 1.0, b: 1.0),
        highlightIntensity: Float = 0.0,
        midtoneIntensity: Float = 0.0,
        shadowIntensity: Float = 0.0
    ) {
        self.highlightColor = highlightColor
        self.midtoneColor = midtoneColor
        self.shadowColor = shadowColor
        self.highlightIntensity = highlightIntensity
        self.midtoneIntensity = midtoneIntensity
        self.shadowIntensity = shadowIntensity
    }
}

/// Color vector for color grading
struct ColorVector: Codable, Hashable {
    let r: Float
    let g: Float
    let b: Float
    
    init(r: Float, g: Float, b: Float) {
        self.r = r
        self.g = g
        self.b = b
    }
}

/// Filter blend modes
enum FilterBlendMode: String, Codable, CaseIterable {
    case normal = "normal"
    case multiply = "multiply"
    case screen = "screen"
    case overlay = "overlay"
    case softLight = "soft_light"
    case hardLight = "hard_light"
    case colorDodge = "color_dodge"
    case colorBurn = "color_burn"
    case darken = "darken"
    case lighten = "lighten"
    case difference = "difference"
    case exclusion = "exclusion"
    
    var ciFilterName: String {
        switch self {
        case .normal: return "CISourceOverCompositing"
        case .multiply: return "CIMultiplyBlendMode"
        case .screen: return "CIScreenBlendMode"
        case .overlay: return "CIOverlayBlendMode"
        case .softLight: return "CISoftLightBlendMode"
        case .hardLight: return "CIHardLightBlendMode"
        case .colorDodge: return "CIColorDodgeBlendMode"
        case .colorBurn: return "CIColorBurnBlendMode"
        case .darken: return "CIDarkenBlendMode"
        case .lighten: return "CILightenBlendMode"
        case .difference: return "CIDifferenceBlendMode"
        case .exclusion: return "CIExclusionBlendMode"
        }
    }
}

/// Filter masking configuration
struct FilterMaskingConfig: Codable, Hashable {
    let maskType: FilterMaskType
    let featherRadius: Float
    let maskInversion: Bool
    let targetAreas: [FacialArea]
    
    init(
        maskType: FilterMaskType,
        featherRadius: Float = 5.0,
        maskInversion: Bool = false,
        targetAreas: [FacialArea] = []
    ) {
        self.maskType = maskType
        self.featherRadius = featherRadius
        self.maskInversion = maskInversion
        self.targetAreas = targetAreas
    }
}

/// Filter mask types
enum FilterMaskType: String, Codable, CaseIterable {
    case none = "none"
    case face = "face"
    case skin = "skin"
    case eyes = "eyes"
    case lips = "lips"
    case hair = "hair"
    case background = "background"
    case custom = "custom"
}

/// Facial areas for targeted filtering
enum FacialArea: String, Codable, CaseIterable {
    case forehead = "forehead"
    case leftEye = "left_eye"
    case rightEye = "right_eye"
    case nose = "nose"
    case leftCheek = "left_cheek"
    case rightCheek = "right_cheek"
    case upperLip = "upper_lip"
    case lowerLip = "lower_lip"
    case chin = "chin"
    case jawline = "jawline"
}

/// Filter complexity levels for performance optimization
enum FilterComplexity: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case extreme = "extreme"
    
    var processingTime: TimeInterval {
        switch self {
        case .low: return 0.1
        case .medium: return 0.3
        case .high: return 0.8
        case .extreme: return 2.0
        }
    }
    
    var memoryUsage: Int {
        switch self {
        case .low: return 50_000_000 // 50MB
        case .medium: return 100_000_000 // 100MB
        case .high: return 200_000_000 // 200MB
        case .extreme: return 400_000_000 // 400MB
        }
    }
}

// MARK: - Makeup Models

/// Virtual makeup application system
struct MakeupLook: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let displayName: String
    let description: String
    let category: MakeupCategory
    let style: MakeupStyle
    let components: [MakeupComponent]
    let isPremium: Bool
    let isPopular: Bool
    let difficulty: MakeupDifficulty
    let estimatedTime: TimeInterval
    let authorInfo: FilterAuthor?
    let socialMetadata: FilterSocialMetadata
    let thumbnailName: String?
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        displayName: String,
        description: String,
        category: MakeupCategory,
        style: MakeupStyle,
        components: [MakeupComponent],
        isPremium: Bool = false,
        isPopular: Bool = false,
        difficulty: MakeupDifficulty = .easy,
        estimatedTime: TimeInterval = 30,
        authorInfo: FilterAuthor? = nil,
        socialMetadata: FilterSocialMetadata = FilterSocialMetadata(),
        thumbnailName: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.description = description
        self.category = category
        self.style = style
        self.components = components
        self.isPremium = isPremium
        self.isPopular = isPopular
        self.difficulty = difficulty
        self.estimatedTime = estimatedTime
        self.authorInfo = authorInfo
        self.socialMetadata = socialMetadata
        self.thumbnailName = thumbnailName
        self.createdAt = createdAt
    }
}

/// Makeup categories
enum MakeupCategory: String, Codable, CaseIterable {
    case natural = "natural"
    case glamour = "glamour"
    case evening = "evening"
    case bridal = "bridal"
    case editorial = "editorial"
    case vintage = "vintage"
    case colorful = "colorful"
    case minimalist = "minimalist"
    case dramatic = "dramatic"
    case seasonal = "seasonal"
    
    var displayName: String {
        switch self {
        case .natural: return "Natural"
        case .glamour: return "Glamour"
        case .evening: return "Evening"
        case .bridal: return "Bridal"
        case .editorial: return "Editorial"
        case .vintage: return "Vintage"
        case .colorful: return "Colorful"
        case .minimalist: return "Minimalist"
        case .dramatic: return "Dramatic"
        case .seasonal: return "Seasonal"
        }
    }
    
    var icon: String {
        switch self {
        case .natural: return "leaf"
        case .glamour: return "sparkles"
        case .evening: return "moon.stars"
        case .bridal: return "heart"
        case .editorial: return "camera"
        case .vintage: return "clock"
        case .colorful: return "paintpalette"
        case .minimalist: return "minus.circle"
        case .dramatic: return "bolt"
        case .seasonal: return "calendar"
        }
    }
}

/// Makeup styles
enum MakeupStyle: String, Codable, CaseIterable {
    case everyday = "everyday"
    case smokyEye = "smoky_eye"
    case wingedEyeliner = "winged_eyeliner"
    case boldLips = "bold_lips"
    case contouring = "contouring"
    case highlighting = "highlighting"
    case colorBlock = "color_block"
    case gradient = "gradient"
    case matte = "matte"
    case glossy = "glossy"
    
    var displayName: String {
        switch self {
        case .everyday: return "Everyday"
        case .smokyEye: return "Smoky Eye"
        case .wingedEyeliner: return "Winged Eyeliner"
        case .boldLips: return "Bold Lips"
        case .contouring: return "Contouring"
        case .highlighting: return "Highlighting"
        case .colorBlock: return "Color Block"
        case .gradient: return "Gradient"
        case .matte: return "Matte"
        case .glossy: return "Glossy"
        }
    }
}

/// Individual makeup components
struct MakeupComponent: Identifiable, Codable, Hashable {
    let id: UUID
    let type: MakeupType
    let color: MakeupColor
    let intensity: Float
    let blendMode: FilterBlendMode
    let applicationArea: [FacialArea]
    let layerOrder: Int
    let isOptional: Bool
    
    init(
        id: UUID = UUID(),
        type: MakeupType,
        color: MakeupColor,
        intensity: Float = 1.0,
        blendMode: FilterBlendMode = .normal,
        applicationArea: [FacialArea],
        layerOrder: Int = 0,
        isOptional: Bool = false
    ) {
        self.id = id
        self.type = type
        self.color = color
        self.intensity = intensity
        self.blendMode = blendMode
        self.applicationArea = applicationArea
        self.layerOrder = layerOrder
        self.isOptional = isOptional
    }
}

/// Makeup types
enum MakeupType: String, Codable, CaseIterable {
    case foundation = "foundation"
    case concealer = "concealer"
    case blush = "blush"
    case bronzer = "bronzer"
    case highlighter = "highlighter"
    case eyeshadow = "eyeshadow"
    case eyeliner = "eyeliner"
    case mascara = "mascara"
    case eyebrows = "eyebrows"
    case lipstick = "lipstick"
    case lipGloss = "lip_gloss"
    case lipLiner = "lip_liner"
    case contour = "contour"
    
    var displayName: String {
        switch self {
        case .foundation: return "Foundation"
        case .concealer: return "Concealer"
        case .blush: return "Blush"
        case .bronzer: return "Bronzer"
        case .highlighter: return "Highlighter"
        case .eyeshadow: return "Eyeshadow"
        case .eyeliner: return "Eyeliner"
        case .mascara: return "Mascara"
        case .eyebrows: return "Eyebrows"
        case .lipstick: return "Lipstick"
        case .lipGloss: return "Lip Gloss"
        case .lipLiner: return "Lip Liner"
        case .contour: return "Contour"
        }
    }
    
    var defaultAreas: [FacialArea] {
        switch self {
        case .foundation, .concealer:
            return [.forehead, .leftCheek, .rightCheek, .nose, .chin]
        case .blush, .bronzer:
            return [.leftCheek, .rightCheek]
        case .highlighter:
            return [.forehead, .nose, .leftCheek, .rightCheek, .chin]
        case .eyeshadow, .eyeliner, .mascara:
            return [.leftEye, .rightEye]
        case .eyebrows:
            return [.leftEye, .rightEye] // Approximating eyebrow area
        case .lipstick, .lipGloss, .lipLiner:
            return [.upperLip, .lowerLip]
        case .contour:
            return [.forehead, .leftCheek, .rightCheek, .nose, .jawline]
        }
    }
}

/// Makeup color definitions
struct MakeupColor: Codable, Hashable {
    let name: String
    let rgb: ColorVector
    let opacity: Float
    let finish: MakeupFinish
    let skinToneCompatibility: [SkinTone]
    
    init(
        name: String,
        rgb: ColorVector,
        opacity: Float = 1.0,
        finish: MakeupFinish = .natural,
        skinToneCompatibility: [SkinTone] = SkinTone.allCases
    ) {
        self.name = name
        self.rgb = rgb
        self.opacity = opacity
        self.finish = finish
        self.skinToneCompatibility = skinToneCompatibility
    }
}

/// Makeup finishes
enum MakeupFinish: String, Codable, CaseIterable {
    case matte = "matte"
    case satin = "satin"
    case natural = "natural"
    case dewy = "dewy"
    case glossy = "glossy"
    case metallic = "metallic"
    case shimmer = "shimmer"
    case glitter = "glitter"
    
    var displayName: String {
        switch self {
        case .matte: return "Matte"
        case .satin: return "Satin"
        case .natural: return "Natural"
        case .dewy: return "Dewy"
        case .glossy: return "Glossy"
        case .metallic: return "Metallic"
        case .shimmer: return "Shimmer"
        case .glitter: return "Glitter"
        }
    }
}

/// Skin tone categories for makeup compatibility
enum SkinTone: String, Codable, CaseIterable {
    case fair = "fair"
    case light = "light"
    case medium = "medium"
    case tan = "tan"
    case deep = "deep"
    case rich = "rich"
    
    var displayName: String {
        switch self {
        case .fair: return "Fair"
        case .light: return "Light"
        case .medium: return "Medium"
        case .tan: return "Tan"
        case .deep: return "Deep"
        case .rich: return "Rich"
        }
    }
}

/// Makeup difficulty levels
enum MakeupDifficulty: String, Codable, CaseIterable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    case expert = "expert"
    
    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .expert: return "Expert"
        }
    }
    
    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .yellow
        case .hard: return .orange
        case .expert: return .red
        }
    }
}

// MARK: - Background Effects Models

/// Background effect configurations
struct BackgroundEffect: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let displayName: String
    let description: String
    let type: BackgroundEffectType
    let category: BackgroundCategory
    let intensity: Float
    let isPremium: Bool
    let processingConfig: BackgroundProcessingConfig
    let thumbnailName: String?
    let socialMetadata: FilterSocialMetadata
    
    init(
        id: UUID = UUID(),
        name: String,
        displayName: String,
        description: String,
        type: BackgroundEffectType,
        category: BackgroundCategory,
        intensity: Float = 1.0,
        isPremium: Bool = false,
        processingConfig: BackgroundProcessingConfig,
        thumbnailName: String? = nil,
        socialMetadata: FilterSocialMetadata = FilterSocialMetadata()
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.description = description
        self.type = type
        self.category = category
        self.intensity = intensity
        self.isPremium = isPremium
        self.processingConfig = processingConfig
        self.thumbnailName = thumbnailName
        self.socialMetadata = socialMetadata
    }
}

/// Background effect types
enum BackgroundEffectType: String, Codable, CaseIterable {
    case blur = "blur"
    case replacement = "replacement"
    case colorGrading = "color_grading"
    case lighting = "lighting"
    case texture = "texture"
    case pattern = "pattern"
    case gradient = "gradient"
    case artistic = "artistic"
    
    var displayName: String {
        switch self {
        case .blur: return "Blur"
        case .replacement: return "Replacement"
        case .colorGrading: return "Color Grading"
        case .lighting: return "Lighting"
        case .texture: return "Texture"
        case .pattern: return "Pattern"
        case .gradient: return "Gradient"
        case .artistic: return "Artistic"
        }
    }
}

/// Background categories
enum BackgroundCategory: String, Codable, CaseIterable {
    case studio = "studio"
    case nature = "nature"
    case urban = "urban"
    case abstract = "abstract"
    case minimalist = "minimalist"
    case luxurious = "luxurious"
    case seasonal = "seasonal"
    case patterns = "patterns"
    
    var displayName: String {
        switch self {
        case .studio: return "Studio"
        case .nature: return "Nature"
        case .urban: return "Urban"
        case .abstract: return "Abstract"
        case .minimalist: return "Minimalist"
        case .luxurious: return "Luxurious"
        case .seasonal: return "Seasonal"
        case .patterns: return "Patterns"
        }
    }
    
    var icon: String {
        switch self {
        case .studio: return "camera.fill"
        case .nature: return "leaf.fill"
        case .urban: return "building.2.fill"
        case .abstract: return "scribble.variable"
        case .minimalist: return "minus.circle.fill"
        case .luxurious: return "crown.fill"
        case .seasonal: return "calendar"
        case .patterns: return "grid"
        }
    }
}

/// Background processing configuration
struct BackgroundProcessingConfig: Codable, Hashable {
    let segmentationModel: SegmentationModel
    let edgeRefinement: EdgeRefinementConfig
    let maskingAccuracy: MaskingAccuracy
    let processingQuality: ProcessingQuality
    let realTimeOptimized: Bool
    
    init(
        segmentationModel: SegmentationModel = .deepLabV3,
        edgeRefinement: EdgeRefinementConfig = EdgeRefinementConfig(),
        maskingAccuracy: MaskingAccuracy = .high,
        processingQuality: ProcessingQuality = .high,
        realTimeOptimized: Bool = false
    ) {
        self.segmentationModel = segmentationModel
        self.edgeRefinement = edgeRefinement
        self.maskingAccuracy = maskingAccuracy
        self.processingQuality = processingQuality
        self.realTimeOptimized = realTimeOptimized
    }
}

/// AI segmentation models
enum SegmentationModel: String, Codable, CaseIterable {
    case deepLabV3 = "deeplab_v3"
    case uNet = "u_net"
    case maskRCNN = "mask_rcnn"
    case portraitNet = "portrait_net"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .deepLabV3: return "DeepLab V3"
        case .uNet: return "U-Net"
        case .maskRCNN: return "Mask R-CNN"
        case .portraitNet: return "PortraitNet"
        case .custom: return "Custom"
        }
    }
    
    var accuracy: Float {
        switch self {
        case .deepLabV3: return 0.95
        case .uNet: return 0.92
        case .maskRCNN: return 0.98
        case .portraitNet: return 0.94
        case .custom: return 0.90
        }
    }
}

/// Edge refinement configuration
struct EdgeRefinementConfig: Codable, Hashable {
    let featherRadius: Float
    let smoothingIterations: Int
    let edgeContrast: Float
    let morphologicalOperations: Bool
    
    init(
        featherRadius: Float = 2.0,
        smoothingIterations: Int = 3,
        edgeContrast: Float = 1.2,
        morphologicalOperations: Bool = true
    ) {
        self.featherRadius = featherRadius
        self.smoothingIterations = smoothingIterations
        self.edgeContrast = edgeContrast
        self.morphologicalOperations = morphologicalOperations
    }
}

/// Masking accuracy levels
enum MaskingAccuracy: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case ultra = "ultra"
    
    var processingTime: TimeInterval {
        switch self {
        case .low: return 0.2
        case .medium: return 0.5
        case .high: return 1.0
        case .ultra: return 2.5
        }
    }
}

/// Processing quality levels
enum ProcessingQuality: String, Codable, CaseIterable {
    case draft = "draft"
    case standard = "standard"
    case high = "high"
    case ultra = "ultra"
    
    var memoryMultiplier: Float {
        switch self {
        case .draft: return 0.5
        case .standard: return 1.0
        case .high: return 2.0
        case .ultra: return 4.0
        }
    }
}

// MARK: - Filter Collection Models

/// User's filter collections and favorites
struct FilterCollection: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let isPrivate: Bool
    let filters: [UUID]
    let makeupLooks: [UUID]
    let backgroundEffects: [UUID]
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        isPrivate: Bool = true,
        filters: [UUID] = [],
        makeupLooks: [UUID] = [],
        backgroundEffects: [UUID] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.isPrivate = isPrivate
        self.filters = filters
        self.makeupLooks = makeupLooks
        self.backgroundEffects = backgroundEffects
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Filter usage analytics
struct FilterUsageAnalytics: Codable {
    let filterId: UUID
    let userId: UUID
    let usageCount: Int
    let totalProcessingTime: TimeInterval
    let averageIntensity: Float
    let lastUsed: Date
    let deviceInfo: DeviceInfo
    let performanceMetrics: PerformanceMetrics
    
    init(
        filterId: UUID,
        userId: UUID,
        usageCount: Int = 1,
        totalProcessingTime: TimeInterval = 0,
        averageIntensity: Float = 1.0,
        lastUsed: Date = Date(),
        deviceInfo: DeviceInfo,
        performanceMetrics: PerformanceMetrics
    ) {
        self.filterId = filterId
        self.userId = userId
        self.usageCount = usageCount
        self.totalProcessingTime = totalProcessingTime
        self.averageIntensity = averageIntensity
        self.lastUsed = lastUsed
        self.deviceInfo = deviceInfo
        self.performanceMetrics = performanceMetrics
    }
}

/// Device information for analytics
struct DeviceInfo: Codable {
    let model: String
    let osVersion: String
    let hasMetalSupport: Bool
    let hasCoreMLSupport: Bool
    let memoryCapacity: Int
    
    init(
        model: String,
        osVersion: String,
        hasMetalSupport: Bool,
        hasCoreMLSupport: Bool,
        memoryCapacity: Int
    ) {
        self.model = model
        self.osVersion = osVersion
        self.hasMetalSupport = hasMetalSupport
        self.hasCoreMLSupport = hasCoreMLSupport
        self.memoryCapacity = memoryCapacity
    }
}

/// Performance metrics for optimization
struct PerformanceMetrics: Codable {
    let processingTime: TimeInterval
    let memoryUsage: Int
    let cpuUsage: Float
    let gpuUsage: Float
    let batteryImpact: BatteryImpact
    let thermalState: ThermalState
    
    init(
        processingTime: TimeInterval,
        memoryUsage: Int,
        cpuUsage: Float,
        gpuUsage: Float,
        batteryImpact: BatteryImpact,
        thermalState: ThermalState
    ) {
        self.processingTime = processingTime
        self.memoryUsage = memoryUsage
        self.cpuUsage = cpuUsage
        self.gpuUsage = gpuUsage
        self.batteryImpact = batteryImpact
        self.thermalState = thermalState
    }
}

/// Battery impact levels
enum BatteryImpact: String, Codable, CaseIterable {
    case minimal = "minimal"
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    case severe = "severe"
}

/// Thermal state levels
enum ThermalState: String, Codable, CaseIterable {
    case nominal = "nominal"
    case fair = "fair"
    case serious = "serious"
    case critical = "critical"
}