//
//  Enhancement.swift
//  Glowly
//
//  Data models for photo enhancements and filters
//

import Foundation
import SwiftUI

/// Represents a single enhancement applied to a photo
struct Enhancement: Identifiable, Codable, Hashable {
    let id: UUID
    let type: EnhancementType
    let intensity: Float
    let parameters: [String: Float]
    let appliedAt: Date
    let processingTime: TimeInterval
    let aiGenerated: Bool
    
    init(
        id: UUID = UUID(),
        type: EnhancementType,
        intensity: Float = 1.0,
        parameters: [String: Float] = [:],
        appliedAt: Date = Date(),
        processingTime: TimeInterval = 0,
        aiGenerated: Bool = false
    ) {
        self.id = id
        self.type = type
        self.intensity = intensity
        self.parameters = parameters
        self.appliedAt = appliedAt
        self.processingTime = processingTime
        self.aiGenerated = aiGenerated
    }
}

/// Types of enhancements available
enum EnhancementType: String, Codable, CaseIterable {
    // Basic Adjustments
    case brightness = "brightness"
    case contrast = "contrast"
    case saturation = "saturation"
    case exposure = "exposure"
    case highlights = "highlights"
    case shadows = "shadows"
    case clarity = "clarity"
    case warmth = "warmth"
    
    // Beauty Enhancements
    case skinSmoothing = "skin_smoothing"
    case skinTone = "skin_tone"
    case blemishRemoval = "blemish_removal"
    case eyeBrightening = "eye_brightening"
    case teethWhitening = "teeth_whitening"
    case lipEnhancement = "lip_enhancement"
    case faceSlimming = "face_slimming"
    case eyeEnlargement = "eye_enlargement"
    
    // Manual Skin Enhancement Tools
    case skinBrightening = "skin_brightening"
    case oilControl = "oil_control"
    case poreMinimizer = "pore_minimizer"
    case skinTemperature = "skin_temperature"
    case acneRemover = "acne_remover"
    case matteFinish = "matte_finish"
    
    // Manual Face Shape Tools
    case jawlineDefinition = "jawline_definition"
    case foreheadAdjustment = "forehead_adjustment"
    case noseReshaping = "nose_reshaping"
    case chinAdjustment = "chin_adjustment"
    case cheekEnhancement = "cheek_enhancement"
    case faceContour = "face_contour"
    
    // Manual Eye Enhancement Tools
    case eyeColorChanger = "eye_color_changer"
    case darkCircleRemoval = "dark_circle_removal"
    case eyelashEnhancement = "eyelash_enhancement"
    case eyebrowShaping = "eyebrow_shaping"
    case eyeSymmetry = "eye_symmetry"
    case eyeContrast = "eye_contrast"
    
    // Manual Mouth and Teeth Tools
    case advancedTeethWhitening = "advanced_teeth_whitening"
    case lipPlumping = "lip_plumping"
    case smileAdjustment = "smile_adjustment"
    case lipColorChanger = "lip_color_changer"
    case lipGloss = "lip_gloss"
    case lipLineDefinition = "lip_line_definition"
    
    // Manual Hair Enhancement Tools
    case hairColorChanger = "hair_color_changer"
    case hairVolumeEnhancement = "hair_volume_enhancement"
    case hairBoundaryRefinement = "hair_boundary_refinement"
    case hairHighlights = "hair_highlights"
    case hairShine = "hair_shine"
    case hairTexture = "hair_texture"
    
    // Manual Body Enhancement Tools
    case bodySlimming = "body_slimming"
    case bodyReshaping = "body_reshaping"
    case heightAdjustment = "height_adjustment"
    case muscleDefinition = "muscle_definition"
    case postureCorrection = "posture_correction"
    case bodyProportioning = "body_proportioning"
    
    // AI-Powered Enhancements
    case autoEnhance = "auto_enhance"
    case portraitMode = "portrait_mode"
    case backgroundBlur = "background_blur"
    case smartFilters = "smart_filters"
    case ageReduction = "age_reduction"
    case makeupApplication = "makeup_application"
    
    var displayName: String {
        switch self {
        case .brightness: return "Brightness"
        case .contrast: return "Contrast"
        case .saturation: return "Saturation"
        case .exposure: return "Exposure"
        case .highlights: return "Highlights"
        case .shadows: return "Shadows"
        case .clarity: return "Clarity"
        case .warmth: return "Warmth"
        case .skinSmoothing: return "Skin Smoothing"
        case .skinTone: return "Skin Tone"
        case .blemishRemoval: return "Blemish Removal"
        case .eyeBrightening: return "Eye Brightening"
        case .teethWhitening: return "Teeth Whitening"
        case .lipEnhancement: return "Lip Enhancement"
        case .faceSlimming: return "Face Slimming"
        case .eyeEnlargement: return "Eye Enlargement"
            
        // Manual Skin Enhancement Tools
        case .skinBrightening: return "Skin Brightening"
        case .oilControl: return "Oil Control"
        case .poreMinimizer: return "Pore Minimizer"
        case .skinTemperature: return "Skin Temperature"
        case .acneRemover: return "Acne Remover"
        case .matteFinish: return "Matte Finish"
        
        // Manual Face Shape Tools
        case .jawlineDefinition: return "Jawline Definition"
        case .foreheadAdjustment: return "Forehead Adjustment"
        case .noseReshaping: return "Nose Reshaping"
        case .chinAdjustment: return "Chin Adjustment"
        case .cheekEnhancement: return "Cheek Enhancement"
        case .faceContour: return "Face Contour"
        
        // Manual Eye Enhancement Tools
        case .eyeColorChanger: return "Eye Color Changer"
        case .darkCircleRemoval: return "Dark Circle Removal"
        case .eyelashEnhancement: return "Eyelash Enhancement"
        case .eyebrowShaping: return "Eyebrow Shaping"
        case .eyeSymmetry: return "Eye Symmetry"
        case .eyeContrast: return "Eye Contrast"
        
        // Manual Mouth and Teeth Tools
        case .advancedTeethWhitening: return "Advanced Teeth Whitening"
        case .lipPlumping: return "Lip Plumping"
        case .smileAdjustment: return "Smile Adjustment"
        case .lipColorChanger: return "Lip Color Changer"
        case .lipGloss: return "Lip Gloss"
        case .lipLineDefinition: return "Lip Line Definition"
        
        // Manual Hair Enhancement Tools
        case .hairColorChanger: return "Hair Color Changer"
        case .hairVolumeEnhancement: return "Hair Volume Enhancement"
        case .hairBoundaryRefinement: return "Hair Boundary Refinement"
        case .hairHighlights: return "Hair Highlights"
        case .hairShine: return "Hair Shine"
        case .hairTexture: return "Hair Texture"
        
        // Manual Body Enhancement Tools
        case .bodySlimming: return "Body Slimming"
        case .bodyReshaping: return "Body Reshaping"
        case .heightAdjustment: return "Height Adjustment"
        case .muscleDefinition: return "Muscle Definition"
        case .postureCorrection: return "Posture Correction"
        case .bodyProportioning: return "Body Proportioning"
            
        case .autoEnhance: return "Auto Enhance"
        case .portraitMode: return "Portrait Mode"
        case .backgroundBlur: return "Background Blur"
        case .smartFilters: return "Smart Filters"
        case .ageReduction: return "Age Reduction"
        case .makeupApplication: return "Makeup Application"
        }
    }
    
    var category: EnhancementCategory {
        switch self {
        case .brightness, .contrast, .saturation, .exposure, .highlights, .shadows, .clarity, .warmth:
            return .basic
        case .skinSmoothing, .skinTone, .blemishRemoval, .eyeBrightening, .teethWhitening, .lipEnhancement, .faceSlimming, .eyeEnlargement:
            return .beauty
        case .skinBrightening, .oilControl, .poreMinimizer, .skinTemperature, .acneRemover, .matteFinish:
            return .skinTools
        case .jawlineDefinition, .foreheadAdjustment, .noseReshaping, .chinAdjustment, .cheekEnhancement, .faceContour:
            return .faceShape
        case .eyeColorChanger, .darkCircleRemoval, .eyelashEnhancement, .eyebrowShaping, .eyeSymmetry, .eyeContrast:
            return .eyeTools
        case .advancedTeethWhitening, .lipPlumping, .smileAdjustment, .lipColorChanger, .lipGloss, .lipLineDefinition:
            return .mouthTools
        case .hairColorChanger, .hairVolumeEnhancement, .hairBoundaryRefinement, .hairHighlights, .hairShine, .hairTexture:
            return .hairTools
        case .bodySlimming, .bodyReshaping, .heightAdjustment, .muscleDefinition, .postureCorrection, .bodyProportioning:
            return .bodyTools
        case .autoEnhance, .portraitMode, .backgroundBlur, .smartFilters, .ageReduction, .makeupApplication:
            return .ai
        }
    }
    
    var isPremium: Bool {
        switch self {
        // AI Tools are premium
        case .autoEnhance, .portraitMode, .backgroundBlur, .smartFilters, .ageReduction, .makeupApplication:
            return true
        // Advanced manual tools are premium
        case .eyeColorChanger, .hairColorChanger, .lipColorChanger, .bodyReshaping, .heightAdjustment, .muscleDefinition, .postureCorrection, .bodyProportioning, .noseReshaping, .jawlineDefinition, .cheekEnhancement, .faceContour:
            return true
        default:
            return false
        }
    }
    
    var defaultIntensity: Float {
        switch self {
        case .autoEnhance:
            return 0.8
        case .skinSmoothing, .skinBrightening, .oilControl, .matteFinish:
            return 0.3
        case .eyeBrightening, .eyeContrast, .eyeEnlargement:
            return 0.4
        case .teethWhitening, .advancedTeethWhitening:
            return 0.2
        case .poreMinimizer, .acneRemover, .darkCircleRemoval:
            return 0.25
        case .faceSlimming, .bodySlimming:
            return 0.15
        case .jawlineDefinition, .chinAdjustment, .cheekEnhancement:
            return 0.2
        case .lipPlumping, .lipGloss, .lipEnhancement:
            return 0.3
        case .eyelashEnhancement, .eyebrowShaping:
            return 0.35
        case .hairVolumeEnhancement, .hairShine:
            return 0.4
        case .noseReshaping, .foreheadAdjustment, .bodyReshaping:
            return 0.1
        case .eyeColorChanger, .hairColorChanger, .lipColorChanger:
            return 0.6
        case .heightAdjustment, .muscleDefinition, .postureCorrection:
            return 0.05
        default:
            return 0.5
        }
    }
}

/// Categories of enhancements
enum EnhancementCategory: String, Codable, CaseIterable {
    case basic = "basic"
    case beauty = "beauty"
    case skinTools = "skin_tools"
    case faceShape = "face_shape"
    case eyeTools = "eye_tools"
    case mouthTools = "mouth_tools"
    case hairTools = "hair_tools"
    case bodyTools = "body_tools"
    case ai = "ai"
    
    var displayName: String {
        switch self {
        case .basic:
            return "Basic"
        case .beauty:
            return "Beauty"
        case .skinTools:
            return "Skin"
        case .faceShape:
            return "Face Shape"
        case .eyeTools:
            return "Eyes"
        case .mouthTools:
            return "Mouth"
        case .hairTools:
            return "Hair"
        case .bodyTools:
            return "Body"
        case .ai:
            return "AI-Powered"
        }
    }
    
    var icon: String {
        switch self {
        case .basic:
            return "slider.horizontal.3"
        case .beauty:
            return "face.smiling"
        case .skinTools:
            return "sparkles"
        case .faceShape:
            return "oval"
        case .eyeTools:
            return "eye"
        case .mouthTools:
            return "mouth"
        case .hairTools:
            return "scissors"
        case .bodyTools:
            return "figure.stand"
        case .ai:
            return "brain.head.profile"
        }
    }
}

/// Predefined enhancement presets
struct EnhancementPreset: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let thumbnail: String?
    let enhancements: [Enhancement]
    let isPremium: Bool
    let category: PresetCategory
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        thumbnail: String? = nil,
        enhancements: [Enhancement],
        isPremium: Bool = false,
        category: PresetCategory
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.thumbnail = thumbnail
        self.enhancements = enhancements
        self.isPremium = isPremium
        self.category = category
    }
}

/// Categories for enhancement presets
enum PresetCategory: String, Codable, CaseIterable {
    case natural = "natural"
    case glamour = "glamour"
    case vintage = "vintage"
    case professional = "professional"
    case artistic = "artistic"
    
    var displayName: String {
        switch self {
        case .natural:
            return "Natural"
        case .glamour:
            return "Glamour"
        case .vintage:
            return "Vintage"
        case .professional:
            return "Professional"
        case .artistic:
            return "Artistic"
        }
    }
}

/// Processing status for enhancements
enum ProcessingStatus: String, Codable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .processing:
            return "Processing"
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        case .cancelled:
            return "Cancelled"
        }
    }
}