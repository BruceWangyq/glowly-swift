//
//  ImageProcessingService.swift
//  Glowly
//
//  Service for image processing and enhancement operations
//

import Foundation
import SwiftUI
import Metal
import MetalKit
import CoreImage
import CoreImage.CIFilterBuiltins

/// Protocol for image processing operations
protocol ImageProcessingServiceProtocol {
    func processImage(_ image: UIImage, with enhancements: [Enhancement]) async throws -> UIImage
    func applyEnhancement(_ enhancement: Enhancement, to image: UIImage) async throws -> UIImage
    func generatePreview(_ image: UIImage, with enhancement: Enhancement, intensity: Float) async throws -> UIImage
    func batchProcess(_ images: [UIImage], with enhancements: [Enhancement]) async throws -> [UIImage]
    func cancelProcessing()
    var isProcessing: Bool { get }
}

/// Implementation of image processing service using Metal and Core Image
@MainActor
final class ImageProcessingService: ImageProcessingServiceProtocol, ObservableObject {
    
    // MARK: - Properties
    @Published var isProcessing = false
    @Published var processingProgress: Float = 0.0
    
    private let metalDevice: MTLDevice?
    private let ciContext: CIContext
    private var currentTask: Task<Void, Never>?
    
    // MARK: - Initialization
    init() {
        // Initialize Metal device for GPU acceleration
        metalDevice = MTLCreateSystemDefaultDevice()
        
        // Create Core Image context with Metal device for better performance
        if let metalDevice = metalDevice {
            ciContext = CIContext(mtlDevice: metalDevice)
        } else {
            // Fallback to CPU if Metal is not available
            ciContext = CIContext()
        }
    }
    
    // MARK: - Main Processing Methods
    
    /// Process an image with multiple enhancements
    func processImage(_ image: UIImage, with enhancements: [Enhancement]) async throws -> UIImage {
        isProcessing = true
        processingProgress = 0.0
        defer { 
            isProcessing = false
            processingProgress = 0.0
        }
        
        var processedImage = image
        let totalEnhancements = Float(enhancements.count)
        
        for (index, enhancement) in enhancements.enumerated() {
            // Check for cancellation
            try Task.checkCancellation()
            
            processedImage = try await applyEnhancement(enhancement, to: processedImage)
            
            // Update progress
            processingProgress = Float(index + 1) / totalEnhancements
        }
        
        return processedImage
    }
    
    /// Apply a single enhancement to an image
    func applyEnhancement(_ enhancement: Enhancement, to image: UIImage) async throws -> UIImage {
        guard let ciImage = CIImage(image: image) else {
            throw ImageProcessingError.invalidImage
        }
        
        let processedCIImage = try await applyEnhancementToCI(enhancement, to: ciImage)
        
        guard let cgImage = ciContext.createCGImage(processedCIImage, from: processedCIImage.extent) else {
            throw ImageProcessingError.processingFailed
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// Generate a preview with specific enhancement and intensity
    func generatePreview(_ image: UIImage, with enhancement: Enhancement, intensity: Float) async throws -> UIImage {
        var modifiedEnhancement = enhancement
        modifiedEnhancement = Enhancement(
            id: enhancement.id,
            type: enhancement.type,
            intensity: intensity,
            parameters: enhancement.parameters,
            appliedAt: enhancement.appliedAt,
            processingTime: enhancement.processingTime,
            aiGenerated: enhancement.aiGenerated
        )
        
        return try await applyEnhancement(modifiedEnhancement, to: image)
    }
    
    /// Process multiple images in batch
    func batchProcess(_ images: [UIImage], with enhancements: [Enhancement]) async throws -> [UIImage] {
        isProcessing = true
        processingProgress = 0.0
        defer {
            isProcessing = false
            processingProgress = 0.0
        }
        
        var processedImages: [UIImage] = []
        let totalImages = Float(images.count)
        
        for (index, image) in images.enumerated() {
            try Task.checkCancellation()
            
            let processedImage = try await processImage(image, with: enhancements)
            processedImages.append(processedImage)
            
            processingProgress = Float(index + 1) / totalImages
        }
        
        return processedImages
    }
    
    /// Cancel current processing operation
    func cancelProcessing() {
        currentTask?.cancel()
        isProcessing = false
        processingProgress = 0.0
    }
    
    // MARK: - Core Image Processing
    
    private func applyEnhancementToCI(_ enhancement: Enhancement, to ciImage: CIImage) async throws -> CIImage {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                do {
                    let result = try self?.processEnhancement(enhancement, ciImage: ciImage) ?? ciImage
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func processEnhancement(_ enhancement: Enhancement, ciImage: CIImage) throws -> CIImage {
        let intensity = enhancement.intensity
        
        switch enhancement.type {
        case .brightness:
            return applyBrightness(to: ciImage, intensity: intensity)
        case .contrast:
            return applyContrast(to: ciImage, intensity: intensity)
        case .saturation:
            return applySaturation(to: ciImage, intensity: intensity)
        case .exposure:
            return applyExposure(to: ciImage, intensity: intensity)
        case .highlights:
            return applyHighlights(to: ciImage, intensity: intensity)
        case .shadows:
            return applyShadows(to: ciImage, intensity: intensity)
        case .clarity:
            return applyClarity(to: ciImage, intensity: intensity)
        case .warmth:
            return applyWarmth(to: ciImage, intensity: intensity)
        case .skinSmoothing:
            return applySkinSmoothing(to: ciImage, intensity: intensity)
        case .skinTone:
            return applySkinTone(to: ciImage, intensity: intensity)
        case .blemishRemoval:
            return applyBlemishRemoval(to: ciImage, intensity: intensity)
        case .eyeBrightening:
            return applyEyeBrightening(to: ciImage, intensity: intensity)
        case .teethWhitening:
            return applyTeethWhitening(to: ciImage, intensity: intensity)
        case .lipEnhancement:
            return applyLipEnhancement(to: ciImage, intensity: intensity)
        case .faceSlimming:
            return applyFaceSlimming(to: ciImage, intensity: intensity)
        case .eyeEnlargement:
            return applyEyeEnlargement(to: ciImage, intensity: intensity)
            
        // Manual Skin Enhancement Tools
        case .skinBrightening:
            return applySkinBrightening(to: ciImage, intensity: intensity)
        case .oilControl:
            return applyOilControl(to: ciImage, intensity: intensity)
        case .poreMinimizer:
            return applyPoreMinimizer(to: ciImage, intensity: intensity)
        case .skinTemperature:
            return applySkinTemperature(to: ciImage, intensity: intensity)
        case .acneRemover:
            return applyAcneRemover(to: ciImage, intensity: intensity)
        case .matteFinish:
            return applyMatteFinish(to: ciImage, intensity: intensity)
            
        // Manual Face Shape Tools
        case .jawlineDefinition:
            return applyJawlineDefinition(to: ciImage, intensity: intensity)
        case .foreheadAdjustment:
            return applyForeheadAdjustment(to: ciImage, intensity: intensity)
        case .noseReshaping:
            return applyNoseReshaping(to: ciImage, intensity: intensity)
        case .chinAdjustment:
            return applyChinAdjustment(to: ciImage, intensity: intensity)
        case .cheekEnhancement:
            return applyCheekEnhancement(to: ciImage, intensity: intensity)
        case .faceContour:
            return applyFaceContour(to: ciImage, intensity: intensity)
            
        // Manual Eye Enhancement Tools
        case .eyeColorChanger:
            return applyEyeColorChanger(to: ciImage, intensity: intensity)
        case .darkCircleRemoval:
            return applyDarkCircleRemoval(to: ciImage, intensity: intensity)
        case .eyelashEnhancement:
            return applyEyelashEnhancement(to: ciImage, intensity: intensity)
        case .eyebrowShaping:
            return applyEyebrowShaping(to: ciImage, intensity: intensity)
        case .eyeSymmetry:
            return applyEyeSymmetry(to: ciImage, intensity: intensity)
        case .eyeContrast:
            return applyEyeContrast(to: ciImage, intensity: intensity)
            
        // Manual Mouth and Teeth Tools
        case .advancedTeethWhitening:
            return applyAdvancedTeethWhitening(to: ciImage, intensity: intensity)
        case .lipPlumping:
            return applyLipPlumping(to: ciImage, intensity: intensity)
        case .smileAdjustment:
            return applySmileAdjustment(to: ciImage, intensity: intensity)
        case .lipColorChanger:
            return applyLipColorChanger(to: ciImage, intensity: intensity)
        case .lipGloss:
            return applyLipGloss(to: ciImage, intensity: intensity)
        case .lipLineDefinition:
            return applyLipLineDefinition(to: ciImage, intensity: intensity)
            
        // Manual Hair Enhancement Tools
        case .hairColorChanger:
            return applyHairColorChanger(to: ciImage, intensity: intensity)
        case .hairVolumeEnhancement:
            return applyHairVolumeEnhancement(to: ciImage, intensity: intensity)
        case .hairBoundaryRefinement:
            return applyHairBoundaryRefinement(to: ciImage, intensity: intensity)
        case .hairHighlights:
            return applyHairHighlights(to: ciImage, intensity: intensity)
        case .hairShine:
            return applyHairShine(to: ciImage, intensity: intensity)
        case .hairTexture:
            return applyHairTexture(to: ciImage, intensity: intensity)
            
        // Manual Body Enhancement Tools
        case .bodySlimming:
            return applyBodySlimming(to: ciImage, intensity: intensity)
        case .bodyReshaping:
            return applyBodyReshaping(to: ciImage, intensity: intensity)
        case .heightAdjustment:
            return applyHeightAdjustment(to: ciImage, intensity: intensity)
        case .muscleDefinition:
            return applyMuscleDefinition(to: ciImage, intensity: intensity)
        case .postureCorrection:
            return applyPostureCorrection(to: ciImage, intensity: intensity)
        case .bodyProportioning:
            return applyBodyProportioning(to: ciImage, intensity: intensity)
        case .autoEnhance:
            return applyAutoEnhance(to: ciImage, intensity: intensity)
        case .portraitMode:
            return applyPortraitMode(to: ciImage, intensity: intensity)
        case .backgroundBlur:
            return applyBackgroundBlur(to: ciImage, intensity: intensity)
        case .smartFilters:
            return applySmartFilters(to: ciImage, intensity: intensity)
        case .ageReduction:
            return applyAgeReduction(to: ciImage, intensity: intensity)
        case .makeupApplication:
            return applyMakeupApplication(to: ciImage, intensity: intensity)
        }
    }
    
    // MARK: - Basic Enhancement Implementations
    
    private func applyBrightness(to image: CIImage, intensity: Float) -> CIImage {
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.brightness = intensity * 0.3 // Scale to reasonable range
        return filter.outputImage ?? image
    }
    
    private func applyContrast(to image: CIImage, intensity: Float) -> CIImage {
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.contrast = 1.0 + (intensity * 0.5) // Range: 1.0 to 1.5
        return filter.outputImage ?? image
    }
    
    private func applySaturation(to image: CIImage, intensity: Float) -> CIImage {
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.saturation = 1.0 + (intensity * 0.5) // Range: 1.0 to 1.5
        return filter.outputImage ?? image
    }
    
    private func applyExposure(to image: CIImage, intensity: Float) -> CIImage {
        let filter = CIFilter.exposureAdjust()
        filter.inputImage = image
        filter.ev = intensity * 2.0 // Range: -2.0 to 2.0
        return filter.outputImage ?? image
    }
    
    private func applyHighlights(to image: CIImage, intensity: Float) -> CIImage {
        let filter = CIFilter.highlightShadowAdjust()
        filter.inputImage = image
        filter.highlightAmount = intensity
        return filter.outputImage ?? image
    }
    
    private func applyShadows(to image: CIImage, intensity: Float) -> CIImage {
        let filter = CIFilter.highlightShadowAdjust()
        filter.inputImage = image
        filter.shadowAmount = intensity
        return filter.outputImage ?? image
    }
    
    private func applyClarity(to image: CIImage, intensity: Float) -> CIImage {
        let filter = CIFilter.unsharpMask()
        filter.inputImage = image
        filter.intensity = intensity * 2.0
        filter.radius = 2.5
        return filter.outputImage ?? image
    }
    
    private func applyWarmth(to image: CIImage, intensity: Float) -> CIImage {
        let filter = CIFilter.temperatureAndTint()
        filter.inputImage = image
        filter.neutral = CIVector(x: 6500 + (intensity * 1000), y: 0) // Adjust color temperature
        return filter.outputImage ?? image
    }
    
    // MARK: - Beauty Enhancement Implementations (Placeholder)
    
    private func applySkinSmoothing(to image: CIImage, intensity: Float) -> CIImage {
        // This would use more sophisticated algorithms like bilateral filtering
        // For now, use a simple blur with masking
        let filter = CIFilter.gaussianBlur()
        filter.inputImage = image
        filter.radius = intensity * 2.0
        return filter.outputImage ?? image
    }
    
    private func applySkinTone(to image: CIImage, intensity: Float) -> CIImage {
        // Placeholder: Apply color adjustment for skin tone
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.brightness = intensity * 0.1
        return filter.outputImage ?? image
    }
    
    private func applyBlemishRemoval(to image: CIImage, intensity: Float) -> CIImage {
        // Placeholder: This would require face detection and targeted healing
        return image
    }
    
    private func applyEyeBrightening(to image: CIImage, intensity: Float) -> CIImage {
        // Placeholder: This would require eye detection and targeted enhancement
        return image
    }
    
    private func applyTeethWhitening(to image: CIImage, intensity: Float) -> CIImage {
        // Placeholder: This would require teeth detection and targeted whitening
        return image
    }
    
    private func applyLipEnhancement(to image: CIImage, intensity: Float) -> CIImage {
        // Placeholder: This would require lip detection and targeted enhancement
        return image
    }
    
    private func applyFaceSlimming(to image: CIImage, intensity: Float) -> CIImage {
        // Placeholder: This would require face detection and geometric transformation
        return image
    }
    
    private func applyEyeEnlargement(to image: CIImage, intensity: Float) -> CIImage {
        // Placeholder: This would require eye detection and geometric transformation
        return image
    }
    
    // MARK: - AI Enhancement Implementations (Placeholder)
    
    private func applyAutoEnhance(to image: CIImage, intensity: Float) -> CIImage {
        // This would use Core ML models for intelligent enhancement
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.contrast = 1.2
        filter.saturation = 1.1
        return filter.outputImage ?? image
    }
    
    private func applyPortraitMode(to image: CIImage, intensity: Float) -> CIImage {
        // This would use depth estimation and background blur
        return image
    }
    
    private func applyBackgroundBlur(to image: CIImage, intensity: Float) -> CIImage {
        // This would use semantic segmentation to separate foreground/background
        return image
    }
    
    private func applySmartFilters(to image: CIImage, intensity: Float) -> CIImage {
        // This would use AI to apply contextually appropriate filters
        return image
    }
    
    private func applyAgeReduction(to image: CIImage, intensity: Float) -> CIImage {
        // This would use AI models for age reduction
        return image
    }
    
    private func applyMakeupApplication(to image: CIImage, intensity: Float) -> CIImage {
        // This would use AI models for virtual makeup application
        return image
    }
    
    // MARK: - Manual Skin Enhancement Implementations
    
    private func applySkinBrightening(to image: CIImage, intensity: Float) -> CIImage {
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.brightness = intensity * 0.2
        filter.contrast = 1.0 + (intensity * 0.1)
        return filter.outputImage ?? image
    }
    
    private func applyOilControl(to image: CIImage, intensity: Float) -> CIImage {
        // Apply a subtle contrast adjustment to reduce shine
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.contrast = 1.0 + (intensity * 0.15)
        filter.saturation = 1.0 - (intensity * 0.1)
        return filter.outputImage ?? image
    }
    
    private func applyPoreMinimizer(to image: CIImage, intensity: Float) -> CIImage {
        // Apply bilateral filter-like effect using gaussian blur and overlay
        let blurFilter = CIFilter.gaussianBlur()
        blurFilter.inputImage = image
        blurFilter.radius = intensity * 1.5
        
        guard let blurred = blurFilter.outputImage else { return image }
        
        let blendFilter = CIFilter.overlayBlendMode()
        blendFilter.inputImage = image
        blendFilter.backgroundImage = blurred
        
        return blendFilter.outputImage ?? image
    }
    
    private func applySkinTemperature(to image: CIImage, intensity: Float) -> CIImage {
        let filter = CIFilter.temperatureAndTint()
        filter.inputImage = image
        // Adjust temperature: negative for cooler, positive for warmer
        let temperatureAdjustment = (intensity - 0.5) * 2000 // -1000 to +1000
        filter.neutral = CIVector(x: 6500 + temperatureAdjustment, y: 0)
        return filter.outputImage ?? image
    }
    
    private func applyAcneRemover(to image: CIImage, intensity: Float) -> CIImage {
        // This would use machine learning for acne detection and healing brush algorithm
        // For now, apply a subtle smoothing effect
        return applySkinSmoothing(to: image, intensity: intensity * 0.5)
    }
    
    private func applyMatteFinish(to image: CIImage, intensity: Float) -> CIImage {
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.saturation = 1.0 - (intensity * 0.2)
        filter.contrast = 1.0 + (intensity * 0.1)
        return filter.outputImage ?? image
    }
    
    // MARK: - Manual Face Shape Enhancement Implementations
    
    private func applyJawlineDefinition(to image: CIImage, intensity: Float) -> CIImage {
        // This would require face detection and targeted enhancement
        // For now, apply subtle contrast enhancement
        let filter = CIFilter.unsharpMask()
        filter.inputImage = image
        filter.intensity = intensity * 0.5
        filter.radius = 1.0
        return filter.outputImage ?? image
    }
    
    private func applyForeheadAdjustment(to image: CIImage, intensity: Float) -> CIImage {
        // This would require geometric transformation
        // Placeholder implementation
        return image
    }
    
    private func applyNoseReshaping(to image: CIImage, intensity: Float) -> CIImage {
        // This would require sophisticated mesh deformation
        // Placeholder implementation
        return image
    }
    
    private func applyChinAdjustment(to image: CIImage, intensity: Float) -> CIImage {
        // This would require mesh deformation
        // Placeholder implementation
        return image
    }
    
    private func applyCheekEnhancement(to image: CIImage, intensity: Float) -> CIImage {
        // Apply subtle color enhancement for cheek highlighting
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.brightness = intensity * 0.05
        filter.saturation = 1.0 + (intensity * 0.1)
        return filter.outputImage ?? image
    }
    
    private func applyFaceContour(to image: CIImage, intensity: Float) -> CIImage {
        // This would use face detection for targeted contouring
        let filter = CIFilter.highlightShadowAdjust()
        filter.inputImage = image
        filter.highlightAmount = intensity * 0.3
        filter.shadowAmount = intensity * 0.2
        return filter.outputImage ?? image
    }
    
    // MARK: - Manual Eye Enhancement Implementations
    
    private func applyEyeColorChanger(to image: CIImage, intensity: Float) -> CIImage {
        // This would require iris detection and color replacement
        // Placeholder implementation with slight color adjustment
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.saturation = 1.0 + (intensity * 0.3)
        return filter.outputImage ?? image
    }
    
    private func applyDarkCircleRemoval(to image: CIImage, intensity: Float) -> CIImage {
        // This would require under-eye detection and targeted brightening
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.brightness = intensity * 0.15
        return filter.outputImage ?? image
    }
    
    private func applyEyelashEnhancement(to image: CIImage, intensity: Float) -> CIImage {
        // This would require eyelash detection and enhancement
        let filter = CIFilter.unsharpMask()
        filter.inputImage = image
        filter.intensity = intensity * 0.8
        filter.radius = 0.5
        return filter.outputImage ?? image
    }
    
    private func applyEyebrowShaping(to image: CIImage, intensity: Float) -> CIImage {
        // This would require eyebrow detection and enhancement
        let filter = CIFilter.unsharpMask()
        filter.inputImage = image
        filter.intensity = intensity * 0.6
        filter.radius = 0.3
        return filter.outputImage ?? image
    }
    
    private func applyEyeSymmetry(to image: CIImage, intensity: Float) -> CIImage {
        // This would require sophisticated eye detection and geometric correction
        // Placeholder implementation
        return image
    }
    
    private func applyEyeContrast(to image: CIImage, intensity: Float) -> CIImage {
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.contrast = 1.0 + (intensity * 0.3)
        return filter.outputImage ?? image
    }
    
    // MARK: - Manual Mouth and Teeth Enhancement Implementations
    
    private func applyAdvancedTeethWhitening(to image: CIImage, intensity: Float) -> CIImage {
        // Advanced version with better targeting
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.brightness = intensity * 0.2
        filter.saturation = 1.0 - (intensity * 0.1)
        return filter.outputImage ?? image
    }
    
    private func applyLipPlumping(to image: CIImage, intensity: Float) -> CIImage {
        // This would require lip detection and subtle geometric enhancement
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.saturation = 1.0 + (intensity * 0.15)
        return filter.outputImage ?? image
    }
    
    private func applySmileAdjustment(to image: CIImage, intensity: Float) -> CIImage {
        // This would require mouth corner detection and geometric adjustment
        // Placeholder implementation
        return image
    }
    
    private func applyLipColorChanger(to image: CIImage, intensity: Float) -> CIImage {
        // This would require lip detection and color replacement
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.saturation = 1.0 + (intensity * 0.4)
        return filter.outputImage ?? image
    }
    
    private func applyLipGloss(to image: CIImage, intensity: Float) -> CIImage {
        // Apply subtle highlight effect for glossy appearance
        let filter = CIFilter.highlightShadowAdjust()
        filter.inputImage = image
        filter.highlightAmount = intensity * 0.3
        return filter.outputImage ?? image
    }
    
    private func applyLipLineDefinition(to image: CIImage, intensity: Float) -> CIImage {
        let filter = CIFilter.unsharpMask()
        filter.inputImage = image
        filter.intensity = intensity * 0.7
        filter.radius = 0.4
        return filter.outputImage ?? image
    }
    
    // MARK: - Manual Hair Enhancement Implementations
    
    private func applyHairColorChanger(to image: CIImage, intensity: Float) -> CIImage {
        // This would require hair segmentation and color replacement
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.saturation = 1.0 + (intensity * 0.5)
        return filter.outputImage ?? image
    }
    
    private func applyHairVolumeEnhancement(to image: CIImage, intensity: Float) -> CIImage {
        // This would require hair detection and texture enhancement
        let filter = CIFilter.unsharpMask()
        filter.inputImage = image
        filter.intensity = intensity * 1.2
        filter.radius = 1.5
        return filter.outputImage ?? image
    }
    
    private func applyHairBoundaryRefinement(to image: CIImage, intensity: Float) -> CIImage {
        let filter = CIFilter.unsharpMask()
        filter.inputImage = image
        filter.intensity = intensity * 0.8
        filter.radius = 0.5
        return filter.outputImage ?? image
    }
    
    private func applyHairHighlights(to image: CIImage, intensity: Float) -> CIImage {
        let filter = CIFilter.highlightShadowAdjust()
        filter.inputImage = image
        filter.highlightAmount = intensity * 0.4
        return filter.outputImage ?? image
    }
    
    private func applyHairShine(to image: CIImage, intensity: Float) -> CIImage {
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.brightness = intensity * 0.1
        filter.contrast = 1.0 + (intensity * 0.15)
        return filter.outputImage ?? image
    }
    
    private func applyHairTexture(to image: CIImage, intensity: Float) -> CIImage {
        let filter = CIFilter.unsharpMask()
        filter.inputImage = image
        filter.intensity = intensity * 1.0
        filter.radius = 0.8
        return filter.outputImage ?? image
    }
    
    // MARK: - Manual Body Enhancement Implementations
    
    private func applyBodySlimming(to image: CIImage, intensity: Float) -> CIImage {
        // This would require body detection and mesh deformation
        // Placeholder with subtle width compression effect
        let transform = CGAffineTransform(scaleX: 1.0 - (intensity * 0.05), y: 1.0)
        return image.transformed(by: transform)
    }
    
    private func applyBodyReshaping(to image: CIImage, intensity: Float) -> CIImage {
        // This would require sophisticated body detection and mesh deformation
        // Placeholder implementation
        return image
    }
    
    private func applyHeightAdjustment(to image: CIImage, intensity: Float) -> CIImage {
        // Subtle vertical stretch/compression
        let scaleY = 1.0 + (intensity - 0.5) * 0.1 // -0.05 to +0.05
        let transform = CGAffineTransform(scaleX: 1.0, y: scaleY)
        return image.transformed(by: transform)
    }
    
    private func applyMuscleDefinition(to image: CIImage, intensity: Float) -> CIImage {
        // Apply subtle contrast and clarity for muscle definition
        let contrastFilter = CIFilter.colorControls()
        contrastFilter.inputImage = image
        contrastFilter.contrast = 1.0 + (intensity * 0.2)
        
        guard let contrastImage = contrastFilter.outputImage else { return image }
        
        let clarityFilter = CIFilter.unsharpMask()
        clarityFilter.inputImage = contrastImage
        clarityFilter.intensity = intensity * 0.5
        clarityFilter.radius = 1.0
        
        return clarityFilter.outputImage ?? contrastImage
    }
    
    private func applyPostureCorrection(to image: CIImage, intensity: Float) -> CIImage {
        // This would require sophisticated body detection and geometric correction
        // Placeholder implementation
        return image
    }
    
    private func applyBodyProportioning(to image: CIImage, intensity: Float) -> CIImage {
        // This would require advanced body detection and proportional adjustments
        // Placeholder implementation
        return image
    }
}

// MARK: - ImageProcessingError

enum ImageProcessingError: LocalizedError {
    case invalidImage
    case processingFailed
    case metalNotAvailable
    case insufficientMemory
    case operationCancelled
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The image format is not supported or the image is corrupted."
        case .processingFailed:
            return "Image processing failed. Please try again."
        case .metalNotAvailable:
            return "Metal GPU acceleration is not available on this device."
        case .insufficientMemory:
            return "Not enough memory available to process this image."
        case .operationCancelled:
            return "The operation was cancelled."
        }
    }
}